# PowerShell completion for aswitch

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -CommandName 'aswitch' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commands = @(
        [CompletionResult]::new('init', 'init', [CompletionResultType]::Command, 'Initialize configuration file'),
        [CompletionResult]::new('providers', 'providers', [CompletionResultType]::Command, 'List configured providers'),
        [CompletionResult]::new('agents', 'agents', [CompletionResultType]::Command, 'List supported agents'),
        [CompletionResult]::new('set', 'set', [CompletionResultType]::Command, 'Set active provider for an agent'),
        [CompletionResult]::new('add', 'add', [CompletionResultType]::Command, 'Add or update provider'),
        [CompletionResult]::new('remove', 'remove', [CompletionResultType]::Command, 'Remove provider'),
        [CompletionResult]::new('help', 'help', [CompletionResultType]::Command, 'Show help'),
        [CompletionResult]::new('version', 'version', [CompletionResultType]::Command, 'Show version')
    )

    $agents = @(
        [CompletionResult]::new('claude', 'claude', [CompletionResultType]::ParameterValue, 'Alias for claude-code'),
        [CompletionResult]::new('opencode', 'opencode', [CompletionResultType]::ParameterValue, 'Alias for open-code'),
        [CompletionResult]::new('openclaw', 'openclaw', [CompletionResultType]::ParameterValue, 'OpenClaw')
    )

    $apiFormats = @(
        [CompletionResult]::new('openai', 'openai', [CompletionResultType]::ParameterValue, 'OpenAI API format'),
        [CompletionResult]::new('anthropic', 'anthropic', [CompletionResultType]::ParameterValue, 'Anthropic API format')
    )

    $addFlags = @(
        [CompletionResult]::new('--name', '--name', [CompletionResultType]::ParameterName, 'Provider name'),
        [CompletionResult]::new('--api-key', '--api-key', [CompletionResultType]::ParameterName, 'Provider API key'),
        [CompletionResult]::new('--model', '--model', [CompletionResultType]::ParameterName, 'Provider model name'),
        [CompletionResult]::new('--openai-base-url', '--openai-base-url', [CompletionResultType]::ParameterName, 'OpenAI-compatible base URL'),
        [CompletionResult]::new('--anthropic-base-url', '--anthropic-base-url', [CompletionResultType]::ParameterName, 'Anthropic-compatible base URL')
    )

    $setFlags = @(
        [CompletionResult]::new('-n', '-n', [CompletionResultType]::ParameterName, 'Print diff without writing config'),
        [CompletionResult]::new('--dry-run', '--dry-run', [CompletionResultType]::ParameterName, 'Print diff without writing config')
    )

    $elements = $commandAst.CommandElements
    $elementCount = $elements.Count

    # Get providers dynamically
    $getProviders = {
        try {
            $output = & aswitch providers 2>$null
            $providers = @()
            foreach ($line in $output) {
                $line = $line.Trim()
                if (-not $line -or $line -eq 'Configured providers:' -or $line -eq 'No providers configured' -or $line.StartsWith('Total:')) {
                    continue
                }
                $providers += [CompletionResult]::new($line, $line, [CompletionResultType]::ParameterValue, $line)
            }
            return $providers
        } catch {
            return @()
        }
    }

    if ($elementCount -eq 1) {
        # Complete main commands
        $commands | Where-Object { $_.CompletionText -like "$wordToComplete*" }
        return
    }

    $currentCommand = $elements[1].Value
    $currentPosition = $elementCount - 1

    switch ($currentCommand) {
        { $_ -in 'set', 'switch' } {
            if ($currentPosition -eq 1) {
                # Complete agent name
                $agents | Where-Object { $_.CompletionText -like "$wordToComplete*" }
                return
            }
            if ($currentPosition -eq 2) {
                # Complete provider name
                & $getProviders | Where-Object { $_.CompletionText -like "$wordToComplete*" }
                return
            }
            if ($currentPosition -eq 3) {
                # Complete api format or flags
                $apiFormats + $setFlags | Where-Object { $_.CompletionText -like "$wordToComplete*" }
                return
            }
            if ($currentPosition -ge 4) {
                # Complete remaining flags
                $setFlags | Where-Object { $_.CompletionText -like "$wordToComplete*" }
                return
            }
        }
        { $_ -in 'remove', 'rm' } {
            if ($currentPosition -eq 1) {
                # Complete provider name
                & $getProviders | Where-Object { $_.CompletionText -like "$wordToComplete*" }
                return
            }
        }
        'add' {
            # Complete add flags
            $addFlags | Where-Object { $_.CompletionText -like "$wordToComplete*" }
            return
        }
        default {
            return
        }
    }
}
