#!/bin/zsh
# ─── Sandbox Zsh Completion ────────────────────────────────────────────────────
# Install: source this file in ~/.zshrc or place in /usr/share/zsh/site-functions/
# Usage: Provides tab completion for sandbox commands
# ─────────────────────────────────────────────────────────────────────────────

_sandbox() {
    local -a actions run_resources status_resources start_resources stop_resources
    local -a restart_resources install_resources uninstall_resources download_resources
    local -a conn_resources logs_resources export_resources import_resources
    local -a batch_resources monitor_resources audit_resources template_resources backup_resources restore_resources

    actions=(
        'run:Execute or connect to a service'
        'status:Show running status of a service'
        'start:Start a service'
        'stop:Stop a service'
        'restart:Restart a service'
        'install:Install Oracle components'
        'uninstall:Uninstall Oracle components'
        'download:Download Oracle components'
        'conn:Manage MCP database connections'
        'logs:View and stream log files'
        'export:Export configuration and state'
        'import:Import configuration'
        'batch:Execute batch operations'
        'monitor:Monitor services'
        'audit:Audit logging and rollback'
        'template:Manage configuration templates'
        'backup:Backup connections, ORDS config, and schemas'
        'restore:Restore from a backup'
        'help:Show help and search commands'
        'shell:Interactive shell mode'
    )

    run_resources=(
        'sqlcl:Connect to database with SQLcl'
        'mcp:Start MCP server'
        'healthcheck:Run health checks'
        'script:Execute oracle admin scripts'
    )

    status_resources=(
        'database:Oracle database status'
        'apex:APEX/ORDS status'
        'mcp:MCP server status'
        'network:Network status'
        'all:All services'
    )

    start_resources=(
        'apex:Start APEX/ORDS'
        'mcp:Start MCP server'
    )

    stop_resources=(
        'apex:Stop APEX/ORDS'
        'mcp:Stop MCP server'
    )

    restart_resources=(
        'apex:Restart APEX/ORDS'
        'mcp:Restart MCP server'
    )

    install_resources=('apex:Install APEX')
    uninstall_resources=('apex:Uninstall APEX')
    download_resources=(
        'apex:Download APEX + ORDS'
    )

    conn_resources=(
        'list:List saved connections'
        'add:Add a new connection'
        'delete:Delete a connection'
        'test:Test a connection'
        'rename:Rename a connection'
    )

    logs_resources=(
        'apex:APEX installation logs'
        'install:All installation logs'
        'ords:ORDS runtime log'
        'startup:Container startup logs'
        'mcp:MCP server log'
        'all:All log files'
    )

    export_resources=(
        'config:Export configuration'
        'connections:Export connections'
        'all:Export all'
    )

    import_resources=(
        'config:Import configuration'
        'connections:Import connections'
        'all:Import all'
    )

    batch_resources=(
        'execute:Execute command batch'
        'apply-connections:Apply connection configuration'
        'apply-commands:Apply command batch'
    )

    monitor_resources=(
        'system:Monitor system'
        'database:Monitor database'
        'apex:Monitor APEX'
        'all:Monitor all'
    )

    audit_resources=(
        'list:List audit entries'
        'show:Show audit details'
        'search:Search audit logs'
        'export:Export audit logs'
        'stats:Show audit statistics'
        'rollback:Rollback operations'
    )

    template_resources=(
        'save:Save configuration template'
        'load:Load configuration template'
        'list:List templates'
        'delete:Delete template'
        'export:Export template'
        'import:Import template'
    )

    backup_resources=(
        'full:Backup everything'
        'connections:Backup saved connections'
        'ords:Backup ORDS configuration'
        'config:Backup sandbox environment config'
        'schemas:Backup Oracle schemas via Data Pump'
        'list:List available backups'
    )

    restore_resources=(
        'full:Restore everything'
        'connections:Restore saved connections'
        'ords:Restore ORDS configuration'
        'config:Restore sandbox environment config'
        'schemas:Restore Oracle schemas via Data Pump'
    )

    local context state line
    if (( CURRENT > 1 )); then
        context="${words[1]}"
    fi

    case "$context" in
        run)      _describe 'resource' run_resources ;;
        status)   _describe 'resource' status_resources ;;
        start)    _describe 'resource' start_resources ;;
        stop)     _describe 'resource' stop_resources ;;
        restart)  _describe 'resource' restart_resources ;;
        install)  _describe 'resource' install_resources ;;
        uninstall) _describe 'resource' uninstall_resources ;;
        download) _describe 'resource' download_resources ;;
        conn)     _describe 'resource' conn_resources ;;
        logs)     _describe 'resource' logs_resources ;;
        export)   _describe 'resource' export_resources ;;
        import)   _describe 'resource' import_resources ;;
        batch)    _describe 'resource' batch_resources ;;
        monitor)  _describe 'resource' monitor_resources ;;
        audit)    _describe 'resource' audit_resources ;;
        template) _describe 'resource' template_resources ;;
        backup)   _describe 'resource' backup_resources ;;
        restore)  _describe 'resource' restore_resources ;;
        help)     _describe 'action' actions ;;
        *)        _describe 'action' actions ;;
    esac
}

# Register the completion
compdef _sandbox sandbox sb sr sc sl ss si sk sp sx
