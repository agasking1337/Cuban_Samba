Clear-Host
Write-Host "Working..."
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WinAPI {
        [DllImport("user32.dll")]
        public static extern short GetAsyncKeyState(int vKey);
    }
"@


function Move-Mouse {

    $currentPos = [System.Windows.Forms.Cursor]::Position
    $currentX = $currentPos.X
    $currentY = $currentPos.Y


    $currentScreen = [System.Windows.Forms.Screen]::FromPoint($currentPos)
    $screenBounds = $currentScreen.Bounds


    $maxDistance = 100  # Adjust the movement range


    $random = New-Object System.Random
    $randomOffsetX = $random.Next(-$maxDistance, $maxDistance)
    $randomOffsetY = $random.Next(-$maxDistance, $maxDistance)


    $targetX = $currentX + $randomOffsetX
    $targetY = $currentY + $randomOffsetY


    $targetX = [Math]::Max($screenBounds.Left, [Math]::Min($screenBounds.Right - 1, $targetX))
    $targetY = [Math]::Max($screenBounds.Top, [Math]::Min($screenBounds.Bottom - 1, $targetY))

    
    $steps = 80 # Number of steps for the mouse to move (more steps = slower, smoother movement)


    $deltaX = ($targetX - $currentX) / $steps
    $deltaY = ($targetY - $currentY) / $steps

    for ($i = 0; $i -lt $steps; $i++) {
        $currentX += $deltaX
        $currentY += $deltaY
        [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new([int]$currentX, [int]$currentY)
        Start-Sleep -Milliseconds 10  # Adjust this delay to control the speed of the movement
    }
}


function Check-KeyboardActivity {
    for ($keyCode = 1; $keyCode -le 255; $keyCode++) {
        if ([WinAPI]::GetAsyncKeyState($keyCode) -ne 0) {
            return $true
        }
    }
    return $false
}

function Monitor-Activity {
    $lastPosition = [System.Windows.Forms.Cursor]::Position
    $inactiveSeconds = 0
    $activeTime = 0
    $isActive = $false

    while ($true) {
        Start-Sleep -Seconds 1

        $currentPosition = [System.Windows.Forms.Cursor]::Position
        $keyboardActive = Check-KeyboardActivity

        if ($currentPosition -ne $lastPosition -or $keyboardActive) {

            $inactiveSeconds = 0

            if (-not $isActive) {
                $isActive = $true
                $activeTime = 0
            }

            $activeTime++
            $Host.UI.RawUI.WindowTitle = "Status: ACTIVE"
        } else {
            $inactiveSeconds++

            if ($isActive -and $inactiveSeconds -ge 35) # Every 35 seconds the mouse will move change if there is no activity
            {
                Move-Mouse
                $isActive = $false
                $Host.UI.RawUI.WindowTitle = "Status: INACTIVE"
            }
        }
        $lastPosition = $currentPosition
    }
}
Monitor-Activity
