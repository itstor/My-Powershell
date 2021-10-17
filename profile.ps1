#Author: itstor
Import-Module PSColor
Import-Module PSGraphQL

$global:foregroundColor = 'white'
$global:homedir = Get-Location

# Settings goes here
$github_token = "GITHUB TOKEN"
$github_username = "GITHUB USERNAME"
$openweather_token = "OPENWEATHER TOKEN"
$openweather_city = "OPENWEATHER CITY"

$time = Get-Date
$curUser = (Get-ChildItem Env:\USERNAME).Value

#connection check
$isConnected = ((Get-NetConnectionProfile).IPv4Connectivity -contains "Internet" -or (Get-NetConnectionProfile).IPv6Connectivity -contains "Internet")

#API CALL
#github api call
if ($isConnected){
	$headers = @{Authorization="Bearer $github_token"}
	$githubapi_uri = "https://api.github.com/graphql"
	$Query = 'query { user ( login: "' + $github_username + '" ) { name contributionsCollection { contributionCalendar { totalContributions } } } }'

	$githubapi_result = Invoke-GraphQLQuery -Query $Query -Headers $headers -Uri $githubapi_uri
	$totalContributions = $githubapi_result.data.user.contributionsCollection.contributionCalendar.totalContributions

	#openweather api call
	$openweatherapi_uri = "https://api.openweathermap.org/data/2.5/weather?id=" + $openweather_city + "&appid=" + $openweather_token
	$waetherapi_result = Invoke-RestMethod -Uri $openweatherapi_uri
}

Set-PSReadLineOption -Colors @{Parameter = "Magenta"; Operator = "Magenta"; Type="Magenta"}

Write-Host "Welcome back, $curUser! " -foregroundColor $foregroundColor -NoNewLine;
Write-Host "$([char]9829) " -foregroundColor Red
if ($isConnected) { Write-Host "🔥🔥 You have contributed $totalContributions on $([char]62472) GitHub this year | Keep it Up!! 🔥🔥" `n }

Write-Host "Today is: $($time.ToLongDateString())" 
if ($isConnected) {
	Write-Host ""
	Write-Host "Current Weather in $($waetherapi_result.name): " -foregroundColor $foregroundColor
	switch ($waetherapi_result.weather[0].main) {
		"Clear" {
			if ($(Get-Date -format HH) -lt 5 -or $(Get-Date -format HH) -gt 18) {
				Write-Host "🌔" -NoNewline
			}
			else {
				Write-Host "🌞" -NoNewline
			}
		}
		"Clouds" {
			Write-Host "☁️" -NoNewline
		}
		"Rain" {
			Write-Host "🌧️" -NoNewline
		}
		"Snow" {
			Write-Host "❄️" -NoNewline
		}
		"Thunderstorm" {
			Write-Host "⛈️" -NoNewline
		}
		"Mist" {
			Write-Host "🌫️" -NoNewline
		}
		default {
			Write-Host "🌤️" -NoNewline
		}
	}
	Write-Host " $($waetherapi_result.weather[0].description) with 🌡️ $($waetherapi_result.main.temp - 273)°C"
	Write-Host "Humidity : 💦 $($waetherapi_result.main.humidity)%"
	Write-Host "Wind Speed : 💨 $($waetherapi_result.wind.speed) m/s"
	Write-Host "Pressure :  $($waetherapi_result.main.pressure) hPa"
}


# Write-Host "$($result)"
function setAsHome {
	$global:homedir = (Get-Location)
}
function goHome {
	Set-Location $homedir
}

function goUserHome {
	Set-Location "C:\Users\$curUser"
}

Set-Alias home goHome
Set-Alias ~ goUserHome
Set-Alias sethome setAsHome
Set-Alias checkgit checkGit

function relativePathToHome {
	$currentPath = (Get-Location).Path
	$currentDrive = (Get-Location).Drive.Root
	$homeDrive = ($homedir).Drive.Root
	if ($currentPath -eq $currentDrive -or $currentDrive -ne $homeDrive) {
		$trimmedRelativePath = $currentPath
	}
	else {
		Set-Location $homedir
		$relativePath = Resolve-Path -relative $currentPath
		$trimmedRelativePath = $relativePath -replace '^..\\'
	}
	Set-Location $currentPath

	return $trimmedRelativePath
}

function Prompt {
	$prompt_logo_background = "Blue"
	$prompt_logo_foreground = "White"
	$prompt_time_background = "Gray"
	$prompt_time_text = "Black"
	$prompt_text = "White"
	$prompt_background = "Blue"
	$prompt_gitstatus_background = "Red"
	$prompt_gitstatus_text = "White"
	$prompt_git_background = "Yellow"
	$prompt_git_text = "Black"
	$prompt_cursor = "Blue"
	$folder_logo = [char]58878

	#check if current dir is git repo
	$isGitRepo = git rev-parse --is-inside-work-tree

	if ($isGitRepo){
		# Current git branch
		$git_string = "null";
		git branch | ForEach-Object {
			if ($_ -match "^\* (.*)"){
				$git_string = $matches[1]
			}
		}

		# Fetch git status
		$git_modified = 0;
		$git_added = 0;
		$git_untracked = 0;

		git status --porcelain | ForEach-Object {
			if ($_ -match "^\?\?") {
				$git_untracked += 1
			}

			if ($_ -match "^ M") {
				$git_modified += 1
			}

			if ($_ -match "^M ") {
				$git_added += 1
			}
		}

		$prompt_cursor = "Red"
		$folder_logo = [char]58877
	}

	#Set folder logo
	if ($homedir.path -eq (Get-Location).path){
		$folder_logo = [char]61461

		if ($isGitRepo){
			$prompt_cursor = "Red"
		}
	}

	$relativePath = relativePathToHome

	Write-Host " $([char]58922) " -foregroundColor $prompt_logo_foreground -backgroundColor $prompt_logo_background -NoNewline
	Write-Host "$([char]57520)" -foregroundColor $prompt_logo_background -backgroundColor $prompt_time_background -NoNewLine
	Write-Host (" $([char]61463) {0:HH}:{0:mm} " -f (Get-Date)) -foregroundColor $prompt_time_text -backgroundColor $prompt_time_background -NoNewLine
	Write-Host "$([char]57520)" -foregroundColor $prompt_time_background -backgroundColor $prompt_background -NoNewLine
	Write-Host " $folder_logo $relativePath " -foregroundColor $prompt_text -backgroundColor $prompt_background -NoNewLine

	if ($isGitRepo) {
		Write-Host  "$([char]57520)" -foregroundColor $prompt_background -NoNewLine -backgroundColor $prompt_git_background
		Write-Host " $([char]57504) $git_string "  -NoNewLine -foregroundColor $prompt_git_text -backgroundColor $prompt_git_background
		Write-Host "$([char]57520)" -foregroundColor $prompt_git_background -backgroundColor $prompt_gitstatus_background -NoNewLine
		Write-Host " $([char]61736) $git_untracked $([char]63722) $git_modified $([char]59177) $git_added " -foregroundColor $prompt_gitstatus_text -backgroundColor $prompt_gitstatus_background -NoNewLine 
	}

	Write-Host  "$([char]57520)$([char]57521)$([char]57521)$([char]57521)" -foregroundColor $prompt_cursor -NoNewLine

	Return " "
}