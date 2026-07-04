import { spawn} from "child_process";
import { Project, Platform } from "./ProjectName";
import { IOS_DESTINATION, WORKSPACE_NAME } from "../Constants/constants";


export async function build(project: Project, platforms?: Platform[]) : Promise<number> { 
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    return new Promise((resolve, _) => {
    const platfromsToBuild = platforms ?? project.supportedPlatforms
    console.log(`build ${project.name} for ${platfromsToBuild.join(', ')}`)
    let commands: string[] = []
    if (project.isSwiftPackage)    {
        commands = [`swift build --package-path ${project.name}`]
    } else {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        commands = platfromsToBuild.map(platform => {
            return `xcodebuild \
            -workspace ${WORKSPACE_NAME}.xcworkspace \
            -scheme ${project.name} \
            -configuration Release \
            -destination "${IOS_DESTINATION}" \
            CODE_SIGN_IDENTITY="-" \
            build`;
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