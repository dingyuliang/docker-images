FROM mcr.microsoft.com/dotnet/framework/sdk:4.8
WORKDIR /gitlab_tools

COPY . ./

# Copy PS Modules to Powershell Module Path, and Powershell will load these module automatically for all sessions.
RUN powershell -Command "Copy-Item -Path ./tools/.ps/Modules/* -Destination ($env:PSModulePath).split(';')[-1] -Recurse -Force"

RUN nuget restore packages.config -PackagesDirectory ./packages

ENV GITLAB_TOOLS_PATH=C:\\gitlab_tools
ENV NUNIT_PATH=$GITLAB_TOOLS_PATH\\packages\\NUnit.ConsoleRunner.3.10.0\\tools\\nunit3-console.exe
ENV OPENCOVER_PATH=$GITLAB_TOOLS_PATH\\packages\\OpenCover.4.7.922\\tools\\OpenCover.Console.exe
ENV ZIP_PATH=$GITLAB_TOOLS_PATH\\packages\\7-Zip.CommandLine.18.1.0\\tools\\7za.exe

CMD [ "powershell"]
