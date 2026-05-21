#import AD module
Import-Module ActiveDirectory

# Import functions
. "$PSScriptRoot\Functions.ps1"

#--------------------------------------Set GUI----------------------------------------

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "JoanLab - Bulk User Creator"
$form.Size = New-Object System.Drawing.Size(500, 300)
$form.StartPosition = "CenterScreen"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select CSV File:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($label)

# Text box to show selected file path
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 45)
$textBox.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($textBox)

# Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(370, 43)
$browseButton.Size = New-Object System.Drawing.Size(80, 25)
$form.Controls.Add($browseButton)

# Output box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 100)
$outputBox.Size = New-Object System.Drawing.Size(440, 120)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)
# Import functions
. "$PSScriptRoot\Functions.ps1"

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "JoanLab - Bulk User Creator"
$form.Size = New-Object System.Drawing.Size(500, 300)
$form.StartPosition = "CenterScreen"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select CSV File:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($label)

# Text box to show selected file path
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 45)
$textBox.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($textBox)

# Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(370, 43)
$browseButton.Size = New-Object System.Drawing.Size(80, 25)
$form.Controls.Add($browseButton)

# Output box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 100)
$outputBox.Size = New-Object System.Drawing.Size(440, 120)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Create Users"
$runButton.Location = New-Object System.Drawing.Point(185, 230)
$runButton.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($runButton)

# Reset button
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Text = "Start Over"
$resetButton.Location = New-Object System.Drawing.Point(320, 230)
$resetButton.Size = New-Object System.Drawing.Size(120, 30)
$resetButton.Enabled = $false
$form.Controls.Add($resetButton)

# Browse button click event
$browseButton.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "CSV Files (*.csv)|*.csv"
    if ($fileDialog.ShowDialog() -eq "OK") {
        $textBox.Text = $fileDialog.FileName
    }
})

$runButton.Add_Click({
    if ($textBox.Text -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please select a CSV file first.")
        return
    }

    $users = Import-Csv -Path $textBox.Text
    $outputBox.Clear()
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $failedUsers = @()
    $createdUsers = @()

    foreach ($user in $users) {
        $result = New-LabADUser -user $user

        if ($result.Status -eq "Success") {
            $outputBox.AppendText("✓ Created: $($result.Username) | Password: $($result.Password)`r`n")
            $createdUsers += [PSCustomObject]@{
                FullName   = "$($user.first_name) $($user.last_name)"
                Email      = "$($result.Username)@joanlab.local"
                Department = $user.Department
                Username   = $result.Username
                UPN        = "$($result.Username)@joanlab.local"
                Password   = $result.Password
            }
        } else {
            $outputBox.AppendText("✗ Failed: $($result.Username) | Reason: $($result.Reason)`r`n")
            $failedUsers += [PSCustomObject]@{
                first_name = $user.first_name
                last_name  = $user.last_name
                Department = $user.Department
                Title      = $user.Title
                Reason     = $result.Reason
            }
        }
    }

    # Export created users to CSV
    if ($createdUsers.Count -gt 0) {
        $createdPath = "$env:USERPROFILE\Documents\created_users_$timestamp.csv"
        $createdUsers | Export-Csv -Path $createdPath -NoTypeInformation
        $outputBox.AppendText("`r`n✓ $($createdUsers.Count) users exported to created_users.csv")
    }

    # Export failed users to CSV
    if ($failedUsers.Count -gt 0) {
        $failedPath = "$env:USERPROFILE\Documents\failed_users_$timestamp.csv"
        $failedUsers | Export-Csv -Path $failedPath -NoTypeInformation
        $outputBox.AppendText("`r`n⚠ $($failedUsers.Count) failed users exported to failed_users.csv")
    }

    if ($createdUsers.Count -gt 0 -and $failedUsers.Count -eq 0) {
        $outputBox.AppendText("`r`n✓ All users created successfully!")
    }

    # Grey out browse and run, enable reset
    $browseButton.Enabled = $false
    $runButton.Enabled = $false
    $resetButton.Enabled = $true
})

$resetButton.Add_Click({
    $textBox.Clear()
    $outputBox.Clear()
    $browseButton.Enabled = $true
    $runButton.Enabled = $true
    $resetButton.Enabled = $false
})

# Show the form
$form.ShowDialog()