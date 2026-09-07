import { execFile } from "node:child_process";
const runSfCommand = (command, args) => new Promise((resolve, reject) => {
    execFile(command, args, { encoding: "utf8", maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
        if (error) {
            reject(error);
            return;
        }
        resolve({ stdout, stderr });
    });
});
export async function resolveSfConnection(targetOrg, run = runSfCommand) {
    try {
        const { stdout } = await run("sf", [
            "org",
            "display",
            "--target-org",
            targetOrg,
            "--json",
            "--verbose",
        ]);
        const result = JSON.parse(stdout);
        const instanceUrl = result.result?.instanceUrl;
        const accessToken = result.result?.accessToken;
        if (result.status !== 0 || !instanceUrl || !accessToken) {
            throw new Error("Invalid Salesforce CLI response");
        }
        return { instanceUrl, accessToken };
    }
    catch {
        throw new Error(`Unable to resolve Salesforce authentication for target org ${targetOrg}`);
    }
}
