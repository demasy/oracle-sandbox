#!/bin/bash
# ─── Sandbox Bash Completion ───────────────────────────────────────────────────
# Install: source this file in ~/.bashrc or /etc/bash_completion.d/
# Usage: Provides tab completion for sandbox commands
# ─────────────────────────────────────────────────────────────────────────────

_sandbox_completion() {
    local cur prev words cword
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Define actions and their resources
    local actions="run status start stop restart install uninstall download conn logs export import batch monitor audit template help shell"
    local run_resources="sqlcl mcp healthcheck script"
    local status_resources="database apex mcp network all"
    local start_resources="apex mcp"
    local stop_resources="apex mcp"
    local restart_resources="apex mcp"
    local install_resources="apex"
    local uninstall_resources="apex"
    local download_resources="apex ords"
    local conn_resources="list add delete test rename"
    local logs_resources="apex install ords startup mcp all"
    local export_resources="config connections all"
    local import_resources="config connections all"
    local batch_resources="apply-connections apply-commands apply-with-rollback execute"
    local monitor_resources="system database apex all"
    local audit_resources="list show search export stats rollback"
    local template_resources="save load list delete export import"

    # Complete first argument (action)
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$actions --help -h --quiet --verbose --dry-run" -- "$cur") )
        return 0
    fi

    # Get the action
    local action="${words[1]}"

    # Complete second argument (resource) based on action
    if [[ $cword -eq 2 ]]; then
        case "$action" in
            run)      COMPREPLY=( $(compgen -W "$run_resources" -- "$cur") ) ;;
            status)   COMPREPLY=( $(compgen -W "$status_resources" -- "$cur") ) ;;
            start)    COMPREPLY=( $(compgen -W "$start_resources" -- "$cur") ) ;;
            stop)     COMPREPLY=( $(compgen -W "$stop_resources" -- "$cur") ) ;;
            restart)  COMPREPLY=( $(compgen -W "$restart_resources" -- "$cur") ) ;;
            install)  COMPREPLY=( $(compgen -W "$install_resources" -- "$cur") ) ;;
            uninstall) COMPREPLY=( $(compgen -W "$uninstall_resources" -- "$cur") ) ;;
            download) COMPREPLY=( $(compgen -W "$download_resources" -- "$cur") ) ;;
            conn)     COMPREPLY=( $(compgen -W "$conn_resources" -- "$cur") ) ;;
            logs)     COMPREPLY=( $(compgen -W "$logs_resources" -- "$cur") ) ;;
            export)   COMPREPLY=( $(compgen -W "$export_resources" -- "$cur") ) ;;
            import)   COMPREPLY=( $(compgen -W "$import_resources" -- "$cur") ) ;;
            batch)    COMPREPLY=( $(compgen -W "$batch_resources" -- "$cur") ) ;;
            monitor)  COMPREPLY=( $(compgen -W "$monitor_resources" -- "$cur") ) ;;
            audit)    COMPREPLY=( $(compgen -W "$audit_resources" -- "$cur") ) ;;
            template) COMPREPLY=( $(compgen -W "$template_resources" -- "$cur") ) ;;
            help)     COMPREPLY=( $(compgen -W "$actions" -- "$cur") ) ;;
            *)        COMPREPLY=() ;;
        esac
        return 0
    fi

    # Complete flags for various commands
    case "$action" in
        status|conn|logs)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--format --follow --lines --help" -- "$cur") )
            fi
            ;;
        run)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--user --pass --pdb --help" -- "$cur") )
            fi
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help --dry-run --verbose --quiet" -- "$cur") )
            fi
            ;;
    esac
}

# Register the completion function
complete -o bashdefault -o default -F _sandbox_completion sandbox sb sr sc sl ss si sk sp sx
