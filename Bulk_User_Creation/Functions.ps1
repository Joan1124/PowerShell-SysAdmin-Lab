# Generates a random password
function New-RandomPassword {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%"
    $password = -join ((1..12) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $password
}

#--------------------------------------------------------------------------------------------------

# Creates a single AD user
function New-LabADUser {
    param($user)
    
    $username = $user.first_name[0] + $user.last_name
    $plainPassword = New-RandomPassword
    $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    try {
    New-ADUser `
        -Name "$($user.first_name) $($user.last_name)" `
        -GivenName $user.first_name `
        -Surname $user.last_name `
        -SamAccountName $username `
        -AccountPassword $securePassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -Path "OU=$($user.Department),OU=Lab Users,OU=My Lab,DC=joanlab,DC=local"

    # Separate try/catch for group assignment
    try {
        $groupMap = @{
            "IT"               = "SG_IT"
            "HR"               = "SG_HR"
            "Sales"            = "SG_Sales"
            "Customer_Service" = "SG_Customer_Service"
        }

        if ($groupMap.ContainsKey($user.Department)) {
            $group = $groupMap[$user.Department]
            Add-ADGroupMember -Identity $group -Members $username
        }
    } catch {
        Write-Host "Group assignment failed for $username : $($_.Exception.Message)"
    }

    return [PSCustomObject]@{
        Status   = "Success"
        Username = $username
        Password = $plainPassword
        Reason   = ""
    }

    } catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
        return [PSCustomObject]@{
            Status   = "Failed"
            Username = $username
            Password = ""
            Reason   = "User already exists"
        }

    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        return [PSCustomObject]@{
            Status   = "Failed"
            Username = $username
            Password = ""
            Reason   = "OU not found for department '$($user.Department)'"
        }

    } catch {
        return [PSCustomObject]@{
            Status   = "Failed"
            Username = $username
            Password = ""
            Reason   = $_.Exception.Message
        }
    }
}

#--------------------------------------------------------------------------------------------------

