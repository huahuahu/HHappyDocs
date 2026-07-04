import {getProject} from './lib/XcodeProject/ProjectName';
import { build } from './lib/XcodeProject/build';
import { test_project } from './lib/XcodeProject/project-test';

import { program } from 'commander';
import { setTimeout } from 'timers/promises';


async function main() {
    program
    .command('build')
    .description('build some project')
    .option('-p, --project [value]', 'Project name')
    .action(async (options) => {
        try {
            const project = getProject(options.project);
            const result = await build(project)
            process.exit(result);
        } catch (error) {
            console.error(`error: ${error}`)
        }
    })
    program
    .command('test')
    .description('test some project')
    .option('-p, --project [value]', 'Project name')
    .action(async (options) => {
        try {
            const project = getProject(options.project);
            const result = await test_project(project)
            process.exit(result);
        } catch (error) {
            console.error(`error: ${error}`)
        }
    })

    program
    .command('test-command')
    .description('test this command line tool')
    .option('-r, --result <VALUE>', 'expected result, success or fail', 'success')
    .action(async (options) => {
        console.log(JSON.stringify(options));
        if (options.result === 'fail') {
            await setTimeout(5000);
            throw new Error('error');
        } else {
            console.log('success');
        }
    })

  
  program.parse(process.argv);
//   const options = program.opts();

//     console.log(JSON.stringify(options));
//     console.log(JSON.stringify(program.commands))
    // if (options.build) {
    //     console.log('build some project');
    //     }
    // else if (options.test) {
    //     console.log('test some project');
    //     }

    // if (options.project) {
    //   await build(hDiary, [Platform.iOS])
    // }
  
}

(async () => {
    try {
        await main();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
})();