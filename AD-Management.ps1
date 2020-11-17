Write-Output "Active Directory Management Script"
Write-Output "----------------------------------------------------"
Write-Output "1. Change computer name (remote or local)" 
Write-Output "2. Change DNS server"
Write-Output "3. Create AD"
Write-Output "4. Promote the current system as Domain Controller"
Write-Output "----------------------------------------------------"

$choice= Read-Host "Enter your selection"


if ($choice -eq 1){ # Change Computer Name
    # Receive User Input
    $adminUser= Read-Host "Enter your Administrative Account name"
    $currentName= Read-Host 'Enter your current computer name (Press "Enter" to change the local machine)'
    $newName= Read-Host "Enter your new computer name" 

    try{
    # Get Domain credential
    $domainName= (Get-ADDomain | Select-Object -Property Name).Name
    $credential="$domainName\$adminUser"
    
        # Change the computer name
        if ($currentName -eq ""){
            Rename-Computer -NewName "$newName" -DomainCredential (Get-Credential $credential) -Force -Restart 
        } else {
            Rename-Computer -ComputerName $currentName -NewName $newName -DomainCredential($credential) -Force -Restart 
        }

    } catch {
        Write-Host "`n[-] Operation failed"
        Write-Host "----------------------ERROR---------------------"
        Write-Host "`n$_"
        Write-Host "------------------------------------------------"
    }


} elseif ($choice -eq 2){ # Edit DNS Server
    $interface= Read-Host "Enter the interface you want to change the DNS setting (Use Get-NetIPAddress for interfaces information)"
    $primaryDNS= Read-Host "Enter your primary DNS server IP"
    $secondaryDNS= Read-Host "Enter your secondary DNS server IP"
    Set-DnsClientServerAddress -InterfaceIndex $interface -ServerAddresses {$primaryDNS,$secondaryDNS}
    Write-Host "[+] DNS server changed successfully to $primaryDNS $secondaryDNS"


} elseif ($choice -eq 3) { # Create AD
    # Receive User input
    $recoverPass= Read-Host "Enter your safemode recovery password" -AsSecureString 
    $domainName= Read-Host "Enter your Active Directory domain name"

    # Install AD service and create a domain
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    Write-Host "`n[+] Active Directory Service installed successfully"
    Install-ADDSForest -DomainName $domainName -InstallDNS -SafeModeAdministratorPassword $recoverPass -Force


} elseif ($choice -eq 4){ # Promote Domain Controller
    try{
        # Install AD service on server
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
        Write-Host "`n[+] Active Directory Service installed successfully"

        # Accept user input
        $adminUser= Write-Host ("`nEnter your Administrative Account name")
        $recoverPass= Read-Host "Enter your safemode recovery password" -AsSecureString 

        # Promote the current machine as Domain Controller
        $domainName= ((Get-ADDomainController | Select-Object -Property Domain).Domain -split "\.")[0] # Extract Domain Name
        $credential="$domainName\$adminUser"
        $fullName=(Get-ADDomainController| Select-Object -Property Domain).Domain
        Install-ADDSDomainController -Credential (Get-Credential $credential) -DomainName $fullName  -SafeModeAdministratorPassword $recoverPass -Force
    } catch {
        Write-Host "`n[-] Operation failed"
        Write-Host "----------------------ERROR---------------------"
        Write-Host "`n$_"
        Write-Host "------------------------------------------------"
    }


} else {
    Write-Host "`n[-] Option does not exist! Try again!"
}