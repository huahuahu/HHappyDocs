export enum Platform {
    iOS = "iOS",
    macOS = "macOS",
    tvOS = "tvOS",
    watchOS = "watchOS"
}



export interface Project {
    // Name for project and file path for swift package
    name: string;
    supportedPlatforms: Platform[];
    isSwiftPackage: boolean;
}

export const hDiary: Project = {
    name: "HDiary",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const clipboardInspector: Project = {
    name: "ClipboardInspector",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const libai: Project = {
    name: "Libai",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const learn: Project = {
    name: "Learn",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const sharedCode: Project = {
    name: "HSharedCode",
    supportedPlatforms: [Platform.iOS, Platform.macOS],
    isSwiftPackage: true
}



export const hSharedCodePackage: Project = {
    name: "HSharedCode-Package",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}


export const hDiaryLibrary: Project = {
    // This is a swift package's path
    name: "MonoRepos/HDiary/HDiaryLibrary",
    supportedPlatforms: [Platform.iOS, Platform.macOS],
    isSwiftPackage: true,
}

export const hDoc: Project = {
    // This is a swift package's path
    name: "HDoc",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false,
}

export const hDocLibrary: Project = {
    // This is a swift package's path
    name: "MonoRepos/HDoc/HDocLibrary",
    supportedPlatforms: [Platform.iOS, Platform.macOS],
    isSwiftPackage: true,
}



// Declare a function that given a string, return specific project. The case is sensitive
export function getProject(projectName: string): Project {
    switch (projectName) {
        case hDiary.name:
            return hDiary;
        case clipboardInspector.name:
            return clipboardInspector;
        case libai.name:
            return libai;
        case learn.name:
            return learn;
        case sharedCode.name:
            return sharedCode;
        case "HDiaryLibrary":
            return hDiaryLibrary;
        case "HDocLibrary":
            return hDocLibrary;
        case hSharedCodePackage.name:
            return hSharedCodePackage;
        case hDoc.name:
            return hDoc;
        default:
            throw new Error(`Unknown project ${projectName}`);
    }
}
