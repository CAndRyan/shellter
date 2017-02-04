Function Set-Window {
    <#
        .SYNOPSIS
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.

        .DESCRIPTION
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.

        .PARAMETER ProcessName
            Name of the process to determine the window characteristics

        .PARAMETER X
            Set the position of the window in pixels from the top.

        .PARAMETER Y
            Set the position of the window in pixels from the left.

        .PARAMETER Width
            Set the width of the window.

        .PARAMETER Height
            Set the height of the window.

        .PARAMETER Passthru
            Display the output object of the window.

        .NOTES
            Name: Set-Window
            Author: Boe Prox
            Version History
                1.0//Boe Prox - 11/24/2015
                    - Initial build
			Url: https://gallery.technet.microsoft.com/scriptcenter/Set-the-position-and-size-54853527
			Editor: Chris Ryan
			
        .OUTPUT
            System.Automation.WindowInfo

        .EXAMPLE
            Get-Process powershell | Set-Window -X 2040 -Y 142 -Passthru

            ProcessName Size     TopLeft  BottomRight
            ----------- ----     -------  -----------
            powershell  1262,642 2040,142 3302,784   

            Description
            -----------
            Set the coordinates on the window for the process PowerShell.exe
        
    #>
    [OutputType('System.Automation.WindowInfo')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipelineByPropertyName=$True)]
        $ProcessName,
		[parameter(ValueFromPipelineByPropertyName=$True)]
		$MainWindowHandle,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$Passthru
    )
    Begin {
        Try{
            [void][Window]
        } Catch {
        Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
        }
    }
    Process {
        $Rectangle = New-Object RECT
		$Handle = $MainWindowHandle	#(Get-Process -Name $ProcessName).MainWindowHandle
        $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
        If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
            $Width = $Rectangle.Right - $Rectangle.Left            
        }
        If (-NOT $PSBoundParameters.ContainsKey('Height')) {
            $Height = $Rectangle.Bottom - $Rectangle.Top
        }
        If ($Return) {
            $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)
        }
        If ($PSBoundParameters.ContainsKey('Passthru')) {
            $Rectangle = New-Object RECT
            $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
            If ($Return) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
                $Width = $Rectangle.Right - $Rectangle.Left
                $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                    Write-Warning "Window is minimized! Coordinates will not be accurate."
                }
                $Object = [pscustomobject]@{
                    ProcessName = $ProcessName
                    Size = $Size
                    TopLeft = $TopLeft
                    BottomRight = $BottomRight
                }
                $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
                $Object            
            }
        }
    }
}

function Set-ShellWindow {
	param(
		[Parameter()]
		[String]
		$Title = "Default",
		
		[Parameter()]
		[Int]
		$Width = 120,
		
		[Parameter()]
		[Int]
		$Height = 30,
		
		[Parameter()]
		[Int]
		$BufferWidth = 120,
		
		[Parameter()]
		[Int]
		$BufferHeight = 3000,
		
		[Parameter()]
		[String]
		$Background = "DarkMagenta",
		
		[Parameter()]
		[String]
		$Foreground = "White",
		
		[Parameter()]
		[Int]
		$Top = -1,
		
		[Parameter()]
		[Int]
		$Left = -1,
		
		[Parameter()]
		[Switch]
		$Custom,
		
		[Parameter()]
		[Switch]
		$Home
	)
	$Shell = $Host.UI.RawUI
	
	if ($Custom) {
		if ($Title -eq "Default") {
			$Title = "Custom"
		}
		$Width = 875	#120
		$Height = 845	#85
		$BufferWidth = 120
		$BufferHeight = 5000
		$Background = "Black"
		$Foreground = "White"
		$Top = 0
		$Left = 1050
	}
	elseif ($Home) {
		if ($Title -eq "Default") {
			$Title = "Home"
		}
		$Width = 120
		$Height = 50
		$BufferWidth = 120
		$BufferHeight = 5000
		$Background = "Black"
		$Foreground = "White"
	}
	
	$shellCount = (Get-Process -Name powershell).Count
	$Title = "PowerShell: " + $Title + " (" + $shellCount + ")"
	$Shell.WindowTitle = $Title
	
	$size = $Shell.BufferSize
	$size.width = $BufferWidth
	$size.height = $BufferHeight
	$Shell.BufferSize = $size
	$Shell.BackgroundColor = $Background
	$Shell.ForegroundColor =  $Foreground
	
	#if ($Top -gt -1 -and $Left -gt -1) {
	#	Get-Process -Name "powershell" |
	#		Where-Object {$_.MainWindowTitle -eq $Title} |
	#		Set-Window -X $Left -Y $Top -Width $Width -Height $Height
	#}
	#else {
	#	$size = $Shell.WindowSize
	#	$size.Width = $Width 
	#	$size.Height = $Height
	#	$Shell.WindowSize = $size
	#}
	
	if ($shellCount -eq 1) {
		Clear-Host
		$PSVersionTable
	}
}
