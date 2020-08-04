# Introduction 
Dockerfiles for creating an ALC compiler image with all default dependencies from Microsoft. Special consideration was to limit the number of environment variables for the `docker run` to an absolute minimum. If additional parameters and / or dependencies are needed you should override the default docker CMD in your `run` command.

This was originally created by https://github.com/navrockclimber/

# Build the image

For building the image you need to specify certain build arguments:

- BASEVEERSION: The base tag for the release channel of your architecture e.g.: 1709, 1803, 1909
- BASETYPE: Select whether you want to use a `nanoserver` or `servercore` base image
- NCHVERSION: The version of Freddy's navcontainerhelper. Only used in the intermediate image for pulling and extracting the artifacts.
- BCTYPE, BCCOUNTRY, BCVERSION, BCSASTOKEN, BCSTORAGEACCOUNT: These arguments are passed into Freddy Scripts. See the possible values in Freddy description of Get-BCArtifactUrl.

The image itself is build by the following:`

```
docker build -t <imagename>:<tag> --build-arg BASEVERSION=<sac tag> --build-arg BASETYPE=<servercore or nanoserver> --build-arg NCHVERSION=<Version> --build-arg BCTYPE=<OnPrem/Sandbox> --build-arg BCCOUNTRY=<de> --build-arg VBCERSION=<16.2.13509.13779> .
```

# Run the container

The most simple variant for running the compiler would be:
```
docker run -v <App Folder Host>:C:\src -v -e RulesetFile="c:\src\Cop.ruleset.json" --name alcnano --rm alc:<tag>
```

If the compile process takes a long time you can try to improve it by granting more memory to the container. This reduced the compile time of about 7000 AL files from over 30 minutes to 3 minutes.
```
docker run -v <App Folder Host>:C:\src -v -e RulesetFile="c:\src\Cop.ruleset.json" --memory 10G --name alcnano --rm alc:<tag>
```

# Choosing the right image

If you don't have any dotnet declarations you should be able to use the much smaller Nanoserver Image. Otherwise you got to choose the servercore image as it contains the .Net framework.

# Converting the output for DevOps

For usage with DevOps you can use the [Convert-ALC-Output.ps1](https://raw.githubusercontent.com/cosmoconsult/cosmo-compiler/master/Convert-ALC-Output.ps1). Just pass the log into the script.
