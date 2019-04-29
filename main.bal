import ballerina/config;
import ballerina/io;
import ballerina/runtime;

import shan1024/chalk;
import shan1024/travis3;

@final string ORGANIZATION_NAME = "ballerina-guides";

@final string[!...] GUIDES = [
    "api-gateway",
    "asynchronous-invocation",
    "ballerina-demo",
    "ballerina-honeycomb",
    "ballerina-with-istio",
    "content-based-routing",
    "data-backed-service",
    "eip-message-transformation",
    "eip-message-construction",
    "gmail-spreadsheet-integration",
    "grpc-service",
    "inter-microservice-communication",
    "loadbalancing-failover",
    "managing-database-transactions",
    "message-filtering",
    "messaging-with-activemq",
    "messaging-with-ballerina",
    "messaging-with-jms-queues",
    "messaging-with-kafka",
    "open-api-based-service",
    "parallel-service-orchestration",
    "pass-through-messaging",
    "playground-async-invocation",
    "playground-circuit-breaker",
    "playground-data-service",
    "playground-external-service",
    "playground-hello-main",
    "playground-hello-service",
    "playground-post-service",
    "playground-streaming",
    "resiliency-circuit-breaker",
    "resiliency-timeouts",
    "restful-service",
    "salesforce-twilio-integration",
    "scatter-gather-messaging",
    "securing-restful-services-with-basic-auth",
    "service-composition",
    "sonarqube-github-integration",
    "stream-processing",
    "websocket-integration"
];

endpoint travis3:Client travisClient {
    authToken: config:getAsString("travis.token"),
    clientConfig: {
        retryConfig: {
            count: 3,
            interval: 1000
        }
    }
};

function setEnvironemtVars(string versionString, string channelString, boolean setRC = false, string rcString = "",
                           boolean setEnvVars = true, boolean triggerBuild = false) {

    chalk:Chalk chalk = new(chalk:BLUE, chalk:DEFAULT);
    io:println(chalk.light().write("SETTING ENVIRONMENT VARIABLES\n"));

    foreach guide in GUIDES {
        chalk = chalk.foreground(chalk:BLUE);
        io:println(chalk.light().write("### " + guide + " ###"));

        if (setEnvVars){
            chalk = chalk.foreground(chalk:YELLOW);
            io:println(chalk.write("Setting environment variable VERSION to `" + versionString + "`"));
            json<travis3:EnvVar> envVar = { ^"env_var.name": "VERSION", ^"env_var.value": versionString,
                ^"env_var.public": true };
            var response = travisClient->createEnvironmentVariable(ORGANIZATION_NAME, guide, envVar);
            io:println(response);

            io:println(chalk.write("Setting environment variable CHANNEL to `" + channelString + "`"));
            envVar = { ^"env_var.name": "CHANNEL", ^"env_var.value": channelString, ^"env_var.public": true };
            response = travisClient->createEnvironmentVariable(ORGANIZATION_NAME, guide, envVar);
            io:println(response);

            if (setRC) {
                io:println(chalk.write("Setting environment variable RC to `" + rcString + "`"));
                envVar = { ^"env_var.name": "RC", ^"env_var.value": rcString, ^"env_var.public": true };
                response = travisClient->createEnvironmentVariable(ORGANIZATION_NAME, guide, envVar);
                io:println(response);
            }
        }
        if (triggerBuild) {
            io:println(chalk.write("Triggering build ..."));
            var response = travisClient->triggerBuild(ORGANIZATION_NAME, guide);
            io:println(response);
        }

        chalk = chalk.foreground(chalk:GREEN);
        io:println(chalk.write("Completed\n"));

        runtime:sleep(1000);
    }
}

function deleteAllEnvVars() {

    chalk:Chalk chalk = new(chalk:BLUE, chalk:DEFAULT);
    io:println(chalk.light().write("DELETING ENVIRONMENT VARIABLES\n"));

    foreach guide in GUIDES {
        chalk = chalk.foreground(chalk:BLUE);
        io:println(chalk.light().write("### " + guide + " ###"));

        try {
            json response = check travisClient->getEnvironmentVariables(ORGANIZATION_NAME, guide);
            io:println(response);

            chalk = chalk.foreground(chalk:YELLOW);

            foreach ev in response.env_vars {
                // Check whether any environment variables are defined.
                match ev.name {
                    () => {
                        // Ignore
                    }
                    json name => {
                        io:print("Name: ");
                        io:println(name);

                        string sid = check <string>ev.id;
                        io:println("id: " + sid);
                        var res = travisClient->deleteEnvironmentVariable(ORGANIZATION_NAME, guide, untaint sid);
                        io:println(res);
                    }
                }
            }
        } catch (error e){
            chalk = chalk.foreground(chalk:RED);
            io:println(chalk.write(e.message));
        }

        chalk = chalk.foreground(chalk:GREEN);
        io:println(chalk.write("Completed\n"));

        runtime:sleep(1000);

    }
}

function main(string... args) {
    string versionString = "0.990.0";
    string channelString = "dev";
    string rcString = "-rc1";
    if (lengthof args == 2) {
        versionString = args[0];
        channelString = args[1];
    }

    deleteAllEnvVars();

    boolean setEnvVars = false;
    boolean triggerBuild = false;

    boolean setRC = false;

    setEnvironemtVars(untaint versionString, untaint channelString, setRC = setRC, rcString = rcString,
        setEnvVars = setEnvVars, triggerBuild = triggerBuild);
}
