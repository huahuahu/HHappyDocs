export enum Platform {
    iOS = "iOS",
    macOS = "macOS",
    tvOS = "tvOS",
    watchOS = "watchOS"
}

export interface Project {
    // Name for project and file path for swift package.
    name: string;
    supportedPlatforms: Platform[];
    isSwiftPackage: boolean;
}

export const hDiary: Project = {
    name: "HDiary",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const hSharedCode: Project = {
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
    // This is a swift package's path.
    name: "MonoRepos/HDiary/HDiaryLibrary",
    supportedPlatforms: [Platform.iOS, Platform.macOS],
    isSwiftPackage: true,
}

// Declare a function that given a string, return specific project. The case is sensitive.
export function getProject(projectName: string): Project {
    switch (projectName) {
        case hDiary.name:
            return hDiary;
        case hSharedCode.name:
            return hSharedCode;
        case "HDiaryLibrary":
            return hDiaryLibrary;
        case hSharedCodePackage.name:
            return hSharedCodePackage;
        default:
            throw new Error(`Unknown project ${projectName}`);
    }
}
