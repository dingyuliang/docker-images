 # Yuliang Ding - 20210401 
# Post Slack Message
# WF-PostSlackMessage -WebHook "https://hooks.slack.com/services/123/456/adafa" -Channel gitlab-builds -MsgTitle "Test Slack using PowerShell" -MsgText "Test Slack using PowerShell - YDING"
function WF-PostSlackMessage{
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [alias("u")]
        [string]
        $WebHook,

        [Parameter(Position = 1, Mandatory = $true)]
        [alias("c")]
        [String]
        $Channel,
        
        [Parameter(Position = 2, Mandatory = $true)]
        [alias("m")]
        [String]
        $MsgTitle,

        [Parameter(Position = 3, Mandatory = $true)]
        [alias("t")]
        [String]
        $MsgText,

        [Parameter()]
        [alias("i")]
        [string]
        $Iconemoji,

        [Parameter()]
        [alias("n")]
        [string]
        $Username,

        [Parameter()]
        [alias("r")]
        [String]
        $MsgColor

    );

    BEGIN{
        if(-not($PSBoundParameters.ContainsKey('Username')) -or !$Username)
        {
            $Username = "Gitlab CI"
        }
        if(-not($PSBoundParameters.ContainsKey('Iconemoji')) -or !$Iconemoji)
        {
            $Iconemoji = ":gitlab:"
        }
        if(-not($PSBoundParameters.ContainsKey('MsgColor')) -or !$MsgColor)
        {
            $MsgColor = "info"
        }
    }

    PROCESS{
        $payload = ConvertTo-Json -Compress @{ channel = $Channel; username = $Username; icon_emoji = $Iconemoji;  pretext = $MsgTitle; text = $MsgText; color = $MsgColor; }
        Invoke-RestMethod -Uri $WebHook -Method Post -Body $payload -ContentType "application/json"
    }

    END{

    }
}

# Yuliang Ding - 20210401
# Post to Artifactory
# https://jfrog.com/knowledge-base/ehow-do-i-execute-a-file-upload-via-powershell/
# https://stackoverflow.com/questions/40096770/artifactory-upload-with-checksum-using-powershell
# Original Command
# $SECURE_PWD = ConvertTo-SecureString -AsPlainText -Force -String $artifactory_pw
# $ARTIFACTORY_CREDENTIALS = New-Object Management.Automation.PSCredential ($artifactory_login, $SECURE_PWD)
# Invoke-RestMethod -uri "$artifactory_url/application/$ENVIRONMENT_FOLDER/$BUILD_VERSION_FULL/$ZIP_PATH" -Method Put -Credential $ARTIFACTORY_CREDENTIALS -InFile $ZIP_PATH -ContentType "multipart/form-data"
# This Function
# WF-PostArtifact -af "application/dev/2021.1.12.101" -n application.zip -f release.zip
function WF-PostArtifact{
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [alias("af")]
        [string]
        $ArtifactFolder,

        [Parameter(Position = 1, Mandatory = $true)]
        [alias("n")]
        [String]
        $ArtifactName,

        [Parameter(Position = 2, Mandatory = $true)]
        [alias("f")]
        [string]
        $ArtifactFilePath,

        [Parameter(Position = 3, Mandatory = $true)]
        [alias("u")]
        [String]
        $ArtifactoryUrl,

        [Parameter()]
        [alias("au")]
        [String]
        $ArtifactoryUser,

        [Parameter()]
        [alias("ap")]
        [String]
        $ArtifactoryPwd,
 
        [Parameter()]
        [alias("ac")]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]
        $ArtifactoryCredential 

    );

    BEGIN{
        if(-not($PSBoundParameters.ContainsKey('ArtifactoryUrl')) -or !$ArtifactoryUrl)
        {
            $ArtifactoryUrl = $artifactory_url
        }
        if(-not($PSBoundParameters.ContainsKey('ArtifactoryUser')) -or !$ArtifactoryUser)
        {
            $ArtifactoryUser = $artifactory_login
        }
        if(-not($PSBoundParameters.ContainsKey('ArtifactoryPwd')) -or !$ArtifactoryPwd)
        {
            $ArtifactoryPwd = $artifactory_pw
        }
        if(-not($PSBoundParameters.ContainsKey('ArtifactoryCredential')) -or !$ArtifactoryCredential)
        {
            $SECURE_PWD = ConvertTo-SecureString -AsPlainText -Force -String $ArtifactoryPwd
            $ArtifactoryCredential = New-Object Management.Automation.PSCredential ($ArtifactoryUser, $SECURE_PWD)
        }
    }

    PROCESS{
        $filePath = WF-GetAbsolutePath($ArtifactFilePath)
        Invoke-RestMethod -uri "$ArtifactoryUrl/$ArtifactFolder/$ArtifactName" -Method Put -Credential $ArtifactoryCredential -InFile $filePath -ContentType "multipart/form-data"
    }

    END{

    }
}

 # Yuliang Ding - 20210401
 # $Form = @{  App = "Application"; Type = "UnitTesting"; CITool = "GitLab"; CodeCoverageTool = "OpenCover"; Branch = "$CI_COMMIT_BRANCH"; Server = "$CI_SERVER_NAME"; RepositoryURL = "$CI_PROJECT_URL"; }
 # WF-HttpClientPost -Uri "https://blo.com" -Form $Form  -FilesKey "Files" -FilePaths "dist\Coverage\CodeCoverage.xml" 
 # Post with Form Fields & Files.
 function WF-HttpClientPost {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0)]
        [string]
        $Uri,

        [Parameter(Position = 1)]
        [HashTable]
        $Form,

        [Parameter(Position = 2, Mandatory = $false)]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(
            ParameterSetName = "FilePaths",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("p")]
        [string[]]
        $FilePaths,

        [Parameter(Mandatory = $false)]
        [string]
        $FilesKey = "Files"
    );

     BEGIN
    {
        foreach($item in $FilePaths)
        {
            $filePath = WF-GetAbsolutePath($item)
            if (-not (Test-Path $filePath))
            {
                $errorMessage = ("File {0} missing or unable to read." -f $filePath)
                $exception =  New-Object System.Exception $errorMessage
			    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, 'MultipartFormDataUpload', ([System.Management.Automation.ErrorCategory]::InvalidArgument), $filePath
			    $PSCmdlet.ThrowTerminatingError($errorRecord)
            }  
        }
    }
    PROCESS
    {
        Add-Type -AssemblyName System.Net.Http
        Add-Type -AssemblyName System.Web

		$httpClientHandler = New-Object System.Net.Http.HttpClientHandler

        if ($Credential)
        {
		    $networkCredential = New-Object System.Net.NetworkCredential @($Credential.UserName, $Credential.Password)
		    $httpClientHandler.Credentials = $networkCredential
        }

        $httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler
        $content = New-Object System.Net.Http.MultipartFormDataContent

        foreach($item in $FilePaths)
        {
            $filePath = WF-GetAbsolutePath($item)
            $mimeType = [System.Web.MimeMapping]::GetMimeMapping($filePath)
            
            if ($mimeType)
            {
                $ContentType = $mimeType
            }
            else
            {
                $ContentType = "application/octet-stream"
            }

            $packageFileStream = New-Object System.IO.FileStream @($filePath, [System.IO.FileMode]::Open)
		    $contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
	        $contentDispositionHeaderValue.Name = "$FilesKey"
		    $contentDispositionHeaderValue.FileName = (Split-Path $filePath -leaf)
            $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
            $streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
            $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $ContentType
        
            $content.Add($streamContent)
        }

        foreach ($key in $Form.Keys) {
            $keyContent = [System.Net.Http.StringContent]::new($Form.Item($key))

            $content.Add($keyContent, $key)
        }

        try
        {
			$response = $httpClient.PostAsync($Uri, $content).Result

			if (!$response.IsSuccessStatusCode)
			{
				$responseBody = $response.Content.ReadAsStringAsync().Result
				$errorMessage = "Status code {0}. Reason {1}. Server reported the following message: {2}." -f $response.StatusCode, $response.ReasonPhrase, $responseBody

				throw [System.Net.Http.HttpRequestException] $errorMessage
			}

			return $response.Content.ReadAsStringAsync().Result
        }
        catch [Exception]
        {
			$PSCmdlet.ThrowTerminatingError($_)
        }
        finally
        {
            if($null -ne $httpClient)
            {
                $httpClient.Dispose()
            }

            if($null -ne $response)
            {
                $response.Dispose()
            }
        }
    }
    END {
    }
}

# Yuliang Ding - 20210401
function WF-GetAbsolutePath {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0)]
        [string]
        $Path
    );
    BEGIN {}
    PROCESS {
        # System.IO.Path.Combine has two properties making it necesarry here:
        #   1) correctly deals with situations where $Path (the second term) is an absolute path
        #   2) correctly deals with situations where $Path (the second term) is relative
        # (join-path) commandlet does not have this first property
        $Path = [System.IO.Path]::Combine(((pwd).Path), ($Path));

        # this piece strips out any relative path modifiers like '..' and '.'
        $Path = [System.IO.Path]::GetFullPath($Path);

        return $Path;
    }
    END {}
} 

# Yuliang Ding - 20210401
# Replace AssemblyVersion and AssemblyFileVersion in AssemblyInfo.cs 
function WF-ReplaceAssemblyVersion {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [alias("f")]
        [string[]]
        $Paths,
        
        [Parameter(Position = 1, Mandatory = $false)]
        [alias("v")]
        [string]
        $Version
    );
    BEGIN {
        if(-not($PSBoundParameters.ContainsKey('Version')) -or !$Version){
            $Version = WF-GenerateAssemblyVersion
        }
    }
    PROCESS {
        foreach($path in $Paths){
            $assemblyVersion = "AssemblyVersion(`"{0}`")" -f $Version
            $assemblyFileVersion = "AssemblyFileVersion(`"{0}`")" -f $Version
            $path = WF-GetAbsolutePath($path)

            (Get-Content $path) `
                -replace 'AssemblyVersion\(.*\)', $assemblyVersion `
                -replace 'AssemblyFileVersion\(.*\)', $assemblyFileVersion |
              Out-File "$path"
        }
    }
    END {}
} 

# Yuliang Ding - 20210401 
# Generate Assmebly Version {yyyy.MM.dd.HHmm}
function WF-GenerateAssemblyVersion {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
    );
    BEGIN {}
    PROCESS {
        return Get-Date -Format "yyyy.MM.dd.HHmm"  
    }
    END {}
} 

# Yuliang Ding - 20210401 
# Get AssemblyVersion from AssemblyInfo.cs
function WF-GetAssemblyVersion {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [alias("f")]
        [string]
        $Path
    );
    BEGIN {
        $Path = WF-GetAbsolutePath($Path)
    }
    PROCESS {
      $VERSION_MATCHES = Select-String -Path $Path -Pattern 'AssemblyVersion\(\"(([0-9]{1,}\.)+[0-9]{1,})\"\)'
      if(($VERSION_MATCHES.Matches.Length -gt 0) -and ($VERSION_MATCHES.Matches[0].Groups.Count -gt 1 )){ 
        return $VERSION_MATCHES.Matches[0].Groups[1].Value 
      }
      Write-Host "Can't find assembly version information."
      return "";
    }
    END {}
} 

 
# Yuliang Ding - 20210518 
# Run Test with VSTest.Console.exe and Generate Code Coverage Report
# Example: WF-OpenCover-VSTest -p unittest\WF.Test\bin\$BUILD_CONFIGURATION_TEST\WF.Test.dll -f "+[WF.*]* -[WF.*Tests*]*" -o distt\Coverage\WF.TestResult.xml
# Actual Commands:
#  - VSTest.Console.exe /Logger:trx /Platform:x64 unittest\WF.Test\bin\$BUILD_CONFIGURATION_TEST\WF.Test.dll
#  - . $OPENCOVER_PATH  -register:path64 -target:"VSTest.Console.exe" -hideskipped:All -oldStyle -targetargs:" /Platform:x64 unittest\WF.Test\bin\$BUILD_CONFIGURATION_TEST\WF.Test.dll" -filter:"+[WF.*]* -[WF.*Tests*]*" -output:"distt\Coverage\WF.TestResult.xml"
function WF-OpenCover-VSTest {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [alias("p")]
        [string]
        $TestDllPath,

        [Parameter(Position = 1, Mandatory = $true)]
        [alias("f")]
        [string]
        $CoverageFilter,

        [Parameter(Position = 2, Mandatory = $true)]
        [alias("o")]
        [string]
        $CoverageOutputPath
    );
    BEGIN {
    }
    PROCESS {
        VSTest.Console.exe /Logger:trx /Platform:x64 $TestDllPath
        . $env:OPENCOVER_PATH  -register:path64 -target:"VSTest.Console.exe" -hideskipped:All -oldStyle -targetargs:" /Platform:x64 $TestDllPath" -filter:$CoverageFilter -output:$CoverageOutputPath
    }
    END {}
}

# Yuliang Ding - 20210518 
# Run Test with NUnit.Console.exe and Generate Code Coverage Report
# Example: WF-OpenCover-NUnit -p Tests\MTClients.Test\MTClients.Test.csproj -f "+[*]* -[MTClients.Test]*" -o distt\Coverage\MTClientsCoverage.xml
# Actual Commands:
#  - . $NUNIT_PATH Tests\MTClients.Test\MTClients.Test.csproj --result=dist\TestResults\MTClientsTestResult.xml
#   - . $OPENCOVER_PATH -register:path64 -target:"$NUNIT_PATH" -targetargs:"Tests\MTClients.Test\MTClients.Test.csproj" -output:"dist\Coverage\MTClientsCoverage.xml" -hideskipped:All -oldStyle -filter:"+[*]* -[MTClients.Test]*"
function WF-OpenCover-NUnit {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [alias("p")]
        [string]
        $TestProjPath,

        [Parameter(Position = 1, Mandatory = $true)]
        [alias("f")]
        [string]
        $CoverageFilter,

        [Parameter(Position = 2, Mandatory = $true)]
        [alias("o")]
        [string]
        $CoverageOutputPath
    );
    BEGIN {
    }
    PROCESS {
        . $env:NUNIT_PATH $TestProjPath
        . $env:OPENCOVER_PATH  -register:path64 -target:"$env:NUNIT_PATH" -hideskipped:All -oldStyle -targetargs:"$TestProjPath" -filter:$CoverageFilter -output:$CoverageOutputPath
    }
    END {}
}