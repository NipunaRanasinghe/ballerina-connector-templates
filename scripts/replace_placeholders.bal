import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;

public type TemplateFileExt ".bal"|".md"|".json"|".yaml"|".yml"|".toml"|".gradle"|".properties";

public function main(string path, string moduleName, string repoName, string moduleVersion, string balVersion) returns error? {

    log:printInfo("Generating connector with the following metadata:");
    log:printInfo("Module Name: " + moduleName);
    log:printInfo("Repository Name: " + repoName);
    log:printInfo("Module Version: " + moduleVersion);
    log:printInfo("Ballerina Version: " + balVersion);

    // Read placeholder values from a config file or environment variables
    [regexp:RegExp, string][] placeholders = [
        [re `\{\{MODULE_NAME_PC\}\}`, moduleName[0].toUpperAscii() + moduleName.substring(1)],
        [re `\{\{MODULE_NAME_CC\}\}`, moduleName[0].toLowerAscii() + moduleName.substring(1)],
        [re `\{\{REPO_NAME\}\}`, regexp:split(re `/`, repoName)[1]],
        [re `\{\{MODULE_VERSION\}\}`, moduleVersion],
        [re `\{\{BAL_VERSION\}\}`, balVersion]
    ];

    // Recursively process all files in the target directory
    check processDirectory(path, placeholders);
}

function processDirectory(string dir, [regexp:RegExp, string][] placeholders) returns error? {
    file:MetaData[] files = check file:readDir(dir);

    foreach file:MetaData file in files {
        if (file.dir) {
            check processDirectory(file.absPath, placeholders);
        } else {
            check processFile(file.absPath, placeholders);
        }
    }
}

function processFile(string filePath, [regexp:RegExp, string][] placeholders) returns error? {
    string[] nameParts = regexp:split(re `\.`, filePath);
    string ext = nameParts[nameParts.length() - 1];
    if ext !is TemplateFileExt {
        log:printInfo("Skipping file: " + filePath);
        return;
    }

    string|error content = check io:fileReadString(filePath);
    if content is error {
        return error("Error reading file at " + filePath + ":" + content.message());
    }

    string strContent = content;
    foreach [regexp:RegExp, string] [placeholder, value] in placeholders {
        strContent = placeholder.replaceAll(strContent, value);
        log:printInfo("Modified content: " + strContent);
    }

    check io:fileWriteString(filePath, strContent);
}
