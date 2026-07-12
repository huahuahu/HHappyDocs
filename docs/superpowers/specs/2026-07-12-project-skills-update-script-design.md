# 项目 Skills 升级脚本设计

## 目标

为当前仓库提供一个可重复执行的 shell 脚本，通过 `npx skills` 将 `skills-lock.json` 管理的全部 project skills 升级到最新版本，并通过 Makefile 暴露简短、稳定的调用入口。

## 范围

本次变更新增 `scripts/update-skills.sh`，并在根目录 `makefile` 中新增 `skills-update` target。脚本只升级当前仓库的 project skills，不升级 global skills，也不接受单个 skill 名称作为参数。

## 脚本行为

`scripts/update-skills.sh` 使用 Bash 执行，并启用严格错误处理。脚本根据自身路径定位仓库根目录，因此调用者可以在任意工作目录中运行它。切换到仓库根目录后，脚本执行：

```bash
npx --yes skills update --project --yes
```

第一个 `--yes` 由 `npx` 使用，避免在需要获取 `skills` CLI 时出现安装确认；第二个 `--yes` 由 `skills update` 使用，跳过 scope 选择提示。因为没有传入 skill 名称，同时显式使用 `--project`，该命令升级当前项目安装的全部 skills。

脚本不设置、删除或覆盖 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 及其小写形式，也不设置 `NO_PROXY`。`npx` 进程完整继承调用者提供的环境。命令失败时，脚本保留非零退出状态，不吞掉错误，也不继续执行其他操作。

## Makefile 入口

根目录 `makefile` 新增 `skills-update` target，调用：

```makefile
skills-update:
	./scripts/update-skills.sh
```

项目维护者可以在仓库根目录执行 `make skills-update` 完成升级，也可以直接调用脚本。

## 测试策略

新增轻量 shell 测试，不访问网络。测试在临时目录中创建一个假的 `npx` 可执行文件，并把它放到 `PATH` 首位，以观察脚本传给 `npx` 的参数、工作目录、环境和退出状态。

测试覆盖以下行为：

1. 从仓库外目录直接调用脚本时，假的 `npx` 在仓库根目录收到 `--yes skills update --project --yes`。
2. 调用者提供的代理变量原样传递给假的 `npx`，证明脚本只继承环境。
3. 假的 `npx` 返回非零状态时，升级脚本返回相同的失败状态。
4. `make skills-update` 会调用升级脚本，并最终向假的 `npx` 传递相同参数。

测试脚本自行创建并清理临时文件，不依赖 Bats、Node package 或其他新增依赖。

## 完成标准

- `scripts/update-skills.sh` 可执行，且从任意工作目录调用时只升级当前仓库的全部 project skills。
- `make skills-update` 提供等价入口。
- 脚本仅继承调用者代理环境，不包含硬编码代理配置。
- 自动化 shell 测试全部通过，且不会实际下载或升级 skills。

