Write-Host "Kubernetes Web UI Dashboard"
Write-Host "This script will fetch, install, run and automatically pop a browser to the right url."

$settings = @{
    webUrl = "https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui"
    yaml = "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml"
    dashboard = "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"    
}

Write-Host ""
Write-Host "More info: $($settings.webUrl)"
Write-Host ""
Write-Host "Prerequisites:"
Write-Host " - Kubernetes is installed and running."
Write-Host ""
Write-Host "This script will:"
Write-Host "  - Launch a browser to the Kubernetes.io web site for you to fetch the latest yaml url for the Web UI Dashboard"
Write-Host "  - Install and run the Web UI Dashboard from that Yaml URL"
Write-Host "  - Fetch the authentication token (needed to login) (to the clipboard)"
Write-Host "  - Launch the Web UI Dashboard.  All you'll have to do is paste that token in the text box and enjoy"
Write-Host ""
$answer = Read-Host "Was this your intention? (y/n)"

if (!($answer -ieq "y" -or $answer -ieq "yes"))
{
    Write-Host "Allright, aborting..."
    exit
}
Start-Process $settings.webUrl

Write-Host "What's the apply command given by that web page ?"
Write-Host "Default: kubectl apply -f $($webUIYaml)"

$webAnswer = Read-Host -Prompt "Enter kubectl apply -f ""URL"" given by the web page. (default above)<enter>"

if ($webAnswer)
{
    $webUIYaml = $webAnswer.Split(" ")[$webAnswer.Split(" ").Length-1]
}

$a = @("apply", "-f",$webUIYaml)
Write-Host "Installing and running the Web UI Dashboard from the yaml"
Write-Host "kubectl $a"
& kubectl $a


$a = @("describe", "secret", "-n", "kube-system")
Write-Host "Installing and running the Web UI Dashboard from the yaml"
Write-Host "kubectl $a"
$s = & kubectl $a

Write-Host "Writing the token to the clipboard"
# $s: all lines from the kubectl command above
#   where-object: filters only those that match the RegEx token: something
#   Take the first one.
#   Remove the "token:" and spaces
#   Put to clipboard
($s | where-object {$_ -match "token:\s*"})[0].Replace("token:","").Trim() | Set-Clipboard

Write-Host "Checking if the Web UI Dashboard is already running"

$dashResult = Invoke-WebRequest -Uri $settings.dashboard

if ($dashResult.StatusCode -eq 200 -and $dashResult.Content.Contains("Kubernetes Dashboard"))
{
    Write-Host "Proxy already running"
}
else 
{
    Write-Host "Starting Kubernetes Web UI Dashboard Server (in a separate window)"
    Start-Process cmd -ArgumentList "/k kubectl proxy"
    
}

Write-Host "Launching browser to Web UI Dashboard, paste the token and login."
Start-Process $settings.dashboard
