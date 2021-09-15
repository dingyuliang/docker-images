FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-3.5
WORKDIR /gitlab_tools

COPY . ./

# Copy PS Modules to Powershell Module Path, and Powershell will load these module automatically for all sessions.
RUN powershell -Command "Copy-Item -Path ./tools/.ps/Modules/* -Destination ($env:PSModulePath).split(';')[-1] -Recurse -Force"

# Copy .NET Framework v3.5 Client Profile to ReferenceAssemblies. (application needs to use ClickOnce relies on .NET Framework 3.5 Client Profile)
# See https://github.com/microsoft/dotnet-framework-docker/blob/cc77ab39d4867eef1e47dbc16ddd51f7da067bde/src/sdk/4.8/windowsservercore-ltsc2019/Dockerfile
# line 65; 
RUN powershell 'Expand-Archive ./tools/.NETFramework/ClientProfile/v3.5.zip -DestinationPath "${env:ProgramFiles(x86)}\Reference` Assemblies\Microsoft\Framework\.NETFramework"'

# Install VS2019 Community. Default Image only includes VS2019 BuildTools, not enough for MSTest Projects in some project;
# See https://stackoverflow.com/questions/41278108/is-it-possible-to-install-visual-studio-in-a-windows-container/46364697
# and https://stackoverflow.com/questions/60138653/ssdt-and-vstest-capability-missing-in-container-when-installing-visual-studio-bu
# and https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2019
RUN Invoke-WebRequest "https://aka.ms/vs/16/release/vs_community.exe" -OutFile "$env:TEMP\vs_community.exe" -UseBasicParsing
RUN & "$env:TEMP\vs_community.exe" --add Microsoft.VisualStudio.Workload.NetWeb --quiet --wait --norestart --noUpdateInstaller | Out-Default

# Set PATH in one layer to keep image size down. Don't put powershell, it will throw error.
# First Match rule, so we need to put VS2019 MSBuild Path as the first one;
RUN setx /M PATH $(\"${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\" + \";${Env:PATH}\")

RUN nuget restore packages.config -PackagesDirectory ./packages

ENV GITLAB_TOOLS_PATH=C:\\gitlab_tools
ENV NUNIT_PATH=$GITLAB_TOOLS_PATH\\packages\\NUnit.ConsoleRunner.3.10.0\\tools\\nunit3-console.exe
ENV OPENCOVER_PATH=$GITLAB_TOOLS_PATH\\packages\\OpenCover.4.7.922\\tools\\OpenCover.Console.exe
ENV 7ZIP_PATH=$GITLAB_TOOLS_PATH\\packages\\7-Zip.CommandLine.18.1.0\\tools\\7za.exe

CMD [ "powershell"]
 
