# escape=`
ARG BASEVERSION
ARG BASETYPE
FROM mcr.microsoft.com/windows/servercore:$BASEVERSION as mother
ARG NCHVERSION
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; `
    Install-Module navcontainerhelper -MinimumVersion $env:NCHVERSION -MaximumVersion $env:NCHVERSION -Force;

ARG BCTYPE
ARG BCCOUNTRY
ARG BCVERSION
ARG BCSTORAGEACCOUNT=bcartifacts
ARG BCSASTOKEN

RUN Import-Module navcontainerhelper; `
    Download-Artifacts -artifactUrl (Get-BCArtifactUrl -type $env:BCTYPE -country $env:BCCOUNTRY -version $env:BCVERSION -storageAccount $env:BCSTORAGEACCOUNT -sasToken $env:BCSASTOKEN) -includePlatform;

RUN New-Item -Path c:\artifacts -ItemType Directory; `
    New-Item -Path c:\bin -ItemType Directory; `
    $basePath = Get-ChildItem "C:\bcartifacts.cache\$env:BCTYPE\$($env:BCVERSION)*"; `
    Start-Process "$basePath\platform\Prerequisite` Components\Open` XML` SDK` 2.5` for` Microsoft` Office\OpenXMLSDKv25.msi" "/qn" -PassThru | Wait-Process; `
    Copy-Item "C:\Program` Files` `(x86`)\Open` XML` SDK\V2.5\lib" "C:\assemblies\OpenXMLSdk" -Recurse; `
    Copy-Item "$basePath\platform\ModernDev\program` files\Microsoft` Dynamics` NAV\*\AL` Development` Environment\ALLanguage.vsix" "$basePath\ALLanguage.zip"; `
    Copy-Item "$basePath\platform\ModernDev\program` files\Microsoft` Dynamics` NAV\*\AL` Development` Environment\System.app" "C:\artifacts\System.app"; `
    Get-ChildItem -Path "$basePath\$env:BCCOUNTRY" -Filter *.app -Recurse | % { Copy-Item $_.FullName  "C:/artifacts/" }; `
    Expand-Archive "$basePath\ALLanguage.zip" "C:\alc"; `
    Copy-Item "$basePath\platform\LegacyDlls\program` files\Microsoft` Dynamics` NAV\*\RoleTailored` Client" "C:\assemblies\RoleTailoredClient" -Recurse; `
    Copy-Item "$basePath\platform\ServiceTier\program` files\Microsoft` Dynamics` NAV\*\Service" "C:\assemblies\Service" -Recurse; `
    Copy-Item "$basePath\platform\Test` Assemblies\Mock` Assemblies" "C:\assemblies\MockAssemblies" -Recurse; 

FROM mcr.microsoft.com/windows/$BASETYPE:$BASEVERSION
COPY --from=mother c:/alc/extension/bin c:/bin
COPY --from=mother C:/artifacts C:/symbols
COPY --from=mother C:/assemblies c:/assemblies
COPY Dummy.ruleset.json c:\dummy.ruleset.json
USER ContainerAdministrator 
RUN if NOT exist c:\windows\assembly ( mkdir c:\windows\assembly )

ENV rulesetfile='c:\dummy.ruleset.json'
CMD c:\bin\win32\alc.exe `
    /project:c:\src `
    /packagecachepath:c:\symbols `
    /out:c:\src\app.app `
    /errorlog:c:\src\alc.log `
    /loglevel:Warning `
    /ruleset:%rulesetfile% `
    /analyzer:c:\bin\Analyzers\Microsoft.Dynamics.Nav.CodeCop.dll `
    /analyzer:c:\bin\Analyzers\Microsoft.Dynamics.Nav.AppSourceCop.dll `
    /analyzer:c:\bin\Analyzers\Microsoft.Dynamics.Nav.UICop.dll `
    /assemblyprobingpaths:"c:\assemblies\OpenXMLSdk","C:\src\.netpackages","C:\assemblies\RoleTailoredClient","C:\assemblies\Service","C:\assemblies\MockAssemblies","c:\windows\assembly"