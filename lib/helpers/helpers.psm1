Function ExecuteCommandsOverSSHwithRetry {
    param($SSHSession, $command, $retryCount=3, $SleepDuration=2)

    $retryCounter = 1
    while ($retryCounter -le $retryCount){
        $CmdInvocation = Invoke-SSHCommand -Command $command -SSHSession $SSHSession -ErrorAction SilentlyContinue
        if ($CmdInvocation.ExitStatus -eq 0) {
            return $CmdInvocation
        }
        else {
            Write-Warning -Message "Command -> $Command invocation failed. Retry counts lef-> ($retryCount - $retryCounter)"
            $retryCounter++        
        }
        Start-Sleep -Seconds $SleepDuration
    }
    throw "SSH Command invocation failed."
}

Function Show-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Message,
        
        [Parameter()]
        [ValidateSet('low','high')] $Severity='low')

    if ($Severity -eq 'low') {
        Write-Host -ForegroundColor Cyan -Object $Message
    }
    else {
        Write-Host -ForegroundColor Red -Object $Message
    }
    
    
}

Function Write-VerboseLog
{

    [CmdletBinding(DefaultParameterSetName='Message')]
    Param
    (
        # Message to be written to the Verbose Stream
        [Parameter(ParameterSetName ='Message',
                        Position=0,
                        ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]        
        [System.String]$Message,

        # In case of calling this from Catch block pass the Invocation info
        [Parameter(ParameterSetName='Error',
                    ValueFromPipeline,
                    ValueFromPipelineByPropertyName)]
        [System.Management.Automation.ErrorRecord]$ErrorInfo
    )
    switch -exact ($PSCmdlet.ParameterSetName) {       
        'Message' {    
            $parentcallstack = (Get-PSCallStack)[1] # store the parent Call Stack        
            $Functionname = $parentcallstack.FunctionName
            $LineNo = $parentcallstack.ScriptLineNumber
            $scriptname = ($parentcallstack.Location -split ':')[0]
            Write-Verbose -Message "$scriptname - $Functionname - LineNo : $LineNo - $Message"    
        }
        'Error' {
            # In case of error, Error Record is passed and we use that to write key info to verbose stream
            $Message = $ErrorInfo.Exception.Message
            $Functionname = $ErrorInfo.InvocationInfo.InvocationName
            $LineNo = $ErrorInfo.InvocationInfo.ScriptLineNumber
            if ($ErrorInfo.InvocationInfo.ScriptName) {
                # this is done to correctly recieve the original error back from Pester mocks
                $scriptname = $(Split-Path -Path $ErrorInfo.InvocationInfo.ScriptName -Leaf)
            }
            Write-Verbose -Message "$scriptname - $Functionname - LineNo : $LineNo - $Message"           
            #$PSCmdlet.ThrowTerminatingError($ErrorInfo)
            #Write-Error -ErrorRecord $ErrorInfo -ErrorAction Stop # throw back the Error record 
        }
    }   
}