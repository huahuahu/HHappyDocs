#!/usr/bin/env python3
"""Run one CI phase with timestamps, bounded waits, and stall diagnostics."""

import datetime
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import threading
import time


def main():
    phase, timeout, *command = sys.argv[1:]
    timeout = int(timeout)
    results = Path(os.environ.get("SNAPSHOT_RESULTS_DIR", "SnapshotResults"))
    results.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    last_output = started
    interrupted = False
    lock = threading.Lock()
    relevant = re.compile(
        r"xcodebuild|swift-frontend|clang|CoreSimulator|Simulator|simulatord|"
        r"testmanagerd|HDiarySnapshotHost|xctest|launchd_sim|SpringBoard|runningboardd"
    )

    with (results / f"{phase}.log").open("w", buffering=1) as log:
        def emit(message):
            timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
            with lock:
                if log.closed:
                    return
                line = f"[{timestamp}] [{phase}] {message}"
                print(line, flush=True)
                log.write(line + "\n")

        def inspect(args, seconds=10):
            try:
                result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                        text=True, errors="replace", timeout=seconds)
                return result.stdout
            except (OSError, subprocess.TimeoutExpired) as error:
                return f"Diagnostic unavailable: {error}\n"

        def diagnose(sample=False):
            emit(inspect(["uptime"]).strip())
            emit(inspect(["vm_stat"]).strip())
            processes = inspect(["ps", "-axo", "pid,ppid,etime,%cpu,%mem,state,comm"])
            rows = [line for line in processes.splitlines() if relevant.search(line)]
            emit("Relevant processes (PID PPID ELAPSED %CPU %MEM STATE COMMAND):\n" + "\n".join(rows))
            if sample:
                # Sample before stopping a stalled test so its waiting stack is preserved.
                candidates = [line for line in rows if re.search(
                    r"xcodebuild|testmanagerd|HDiarySnapshotHost|xctest|CoreSimulatorService", line)]
                for row in candidates[:8]:
                    pid = row.split()[0]
                    if pid.isdigit():
                        path = results / f"{phase}-{int(time.monotonic() - started)}-pid-{pid}.sample.txt"
                        emit(inspect(["sample", pid, "1", "10", "-file", str(path)], 8).strip())

        def request_stop(_signum, _frame):
            nonlocal interrupted
            interrupted = True

        signal.signal(signal.SIGTERM, request_stop)
        signal.signal(signal.SIGINT, request_stop)
        emit(f"HOST {os.uname()} cpu_count={os.cpu_count()}")
        emit(f"START timeout={timeout}s command={command!r}")
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, errors="replace", start_new_session=True)

        def forward_output():
            nonlocal last_output
            for line in process.stdout:
                last_output = time.monotonic()
                emit(line.rstrip("\n"))

        reader = threading.Thread(target=forward_output, daemon=True)
        reader.start()
        next_heartbeat = started
        last_sample = started - 300
        forced_exit = None
        while process.poll() is None:
            now = time.monotonic()
            if interrupted or now - started >= timeout:
                forced_exit = 130 if interrupted else 124
                emit("INTERRUPTED" if interrupted else f"TIMEOUT after {timeout}s")
                diagnose(sample=True)
                # Stop only this phase's process group, allowing artifact upload to run.
                for sig, grace in ((signal.SIGINT, 20), (signal.SIGTERM, 5), (signal.SIGKILL, 5)):
                    try:
                        os.killpg(process.pid, sig)
                    except ProcessLookupError:
                        break
                    deadline = time.monotonic() + grace
                    while time.monotonic() < deadline:
                        process.poll()
                        try:
                            os.killpg(process.pid, 0)
                        except ProcessLookupError:
                            break
                        time.sleep(0.2)
                    else:
                        continue
                    break
                break
            if now >= next_heartbeat:
                idle = now - last_output
                emit(f"HEARTBEAT elapsed={int(now - started)}s no-command-output={int(idle)}s")
                sampling = idle >= 120 and now - last_sample >= 300
                diagnose(sample=sampling)
                if sampling:
                    last_sample = time.monotonic()
                next_heartbeat = time.monotonic() + 60
            time.sleep(1)
        reader.join(timeout=5)
        code = forced_exit if forced_exit is not None else process.returncode
        emit(f"END elapsed={int(time.monotonic() - started)}s exit={code}")
        summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if summary:
            with open(summary, "a") as output:
                output.write(f"- **{phase}**: {int(time.monotonic() - started)}s, exit `{code}`\n")
        return code


if __name__ == "__main__":
    sys.exit(main())
