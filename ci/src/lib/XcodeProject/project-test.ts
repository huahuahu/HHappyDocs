// declare a function that can used to call xcodebuild to build the project

import { spawn} from "child_process";
import { Project, Platform } from "./ProjectName";
import { IOS_DESTINATION } from "../Constants/constants";


export async function test_project(project: Project, platforms?: Platform[]) : Promise<number> { 
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    return new Promise((resolve, _) => {
    
    const workspace = "MonoProjects";
    const platfromsToBuild = platforms ?? project.supportedPlatforms
    console.log(`build ${project.name} for ${platfromsToBuild.join(', ')}`)
    let commands: string[] = []
    if (project.isSwiftPackage)    {
        commands = [`swift test --package-path ${project.name}`]
    } else {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        commands = platfromsToBuild.map(platform => {
            return `xcodebuild clean test \
            -workspace ${workspace}.xcworkspace \
            -scheme ${project.name} \
            -configuration Debug \
            -destination "${IOS_DESTINATION}" \
            CODE_SIGN_IDENTITY="-"`;
        })
        
    }

    console.log(commands);
    const shell = spawn('/bin/sh', [], { stdio: 'pipe' });

    shell.stdout.on('data', (data) => {
        console.log(`stdout: ${data}`);
    });
    
    shell.stderr.on('data', (data) => {
        console.error(`stderr: ${data}`);
    });
    shell.stdin.write('pwd\n');
    shell.stdin.write('cd ..\n');
    shell.stdin.write('pwd\n');
    commands.forEach(command => {
        shell.stdin.write(`${command}\n`);
    })
    shell.on('close', (code) => {
        resolve(code);
    });
    shell.stdin.end();
})
}
