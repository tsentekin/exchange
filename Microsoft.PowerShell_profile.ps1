 oh-my-posh init pwsh --config 'C:\Users\tsenteki\AppData\Local\Programs\oh-my-posh\themes\catppuccin_mocha.omp.json' | Invoke-Expression
 # Check if the calling script is related to AppX modules
if ((Get-PSCallStack)[1].Position.Text -match '\bAppX') {
    # Import all available modules, skipping edition checks
    Get-Module -ListAvailable | Import-Module 
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}



#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
