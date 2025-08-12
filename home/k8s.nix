{pkgs, ...}: {
  home.packages = with pkgs; [
    jq
    yq
    kubectl
    kubectx
    fluxcd
    kubernetes-helm
  ];

  home.shellAliases = {
    k = "kubectl";
    pods = "kubectl get pods --all-namespaces";
    wp = "watch -n 0.1 'kubectl get pods --all-namespaces'";
    fl = "flux logs --all-namespaces";
    fra = "flux reconcile kustomization flux-system --with-source";
  };

  programs = {
    zsh = {
      initContent = ''
        unalias kl 2>/dev/null
        kl() {
          local query=""
          local kubectl_args=()

          kl_help() {
            echo "Usage: kl [OPTIONS] [-- KUBECTL_ARGS]"
            echo
            echo "View logs of a Kubernetes pod."
            echo
            echo "Options:"
            echo "  -q, --query QUERY    Pre-fill the pod selection search"
            echo "  -h, --help           Display this help message"
            echo
            echo "Examples:"
            echo "  kl                   # Interactive pod selection"
            echo "  kl -q nginx          # Pre-fill 'nginx' in pod selection"
            echo "  kl -- --tail=100     # Show last 100 lines of logs"
          }

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -h|--help)
                kl_help
                return 0
                ;;
              -q|--query)
                query="$2"
                shift 2
                ;;
              --)
                shift
                kubectl_args+=("$@")
                break
                ;;
              *)
                kubectl_args+=("$1")
                shift
                ;;
            esac
          done

          local selected_pod=$(kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers |
            fzf --select-1 --query="$query")

          if [[ -n $selected_pod ]]; then
            local namespace=$(echo $selected_pod | awk '{print $1}')
            local pod_name=$(echo $selected_pod | awk '{print $2}')
            kubectl logs -n "$namespace" "$pod_name" "''${kubectl_args[@]}"
          else
            echo "No pod selected."
          fi
        }

        unalias kd 2>/dev/null
        kd() {
          local query=""
          local resource_type="pod"
          local kubectl_args=()

          kd_help() {
            echo "Usage: kd [OPTIONS] [-- KUBECTL_ARGS]"
            echo
            echo "Describe a Kubernetes resource."
            echo
            echo "Options:"
            echo "  -q, --query QUERY    Pre-fill the resource selection search"
            echo "  -t, --type TYPE      Specify the resource type (default: pod)"
            echo "  -h, --help           Display this help message"
            echo
            echo "Examples:"
            echo "  kd                   # Describe a pod (interactive selection)"
            echo "  kd -q nginx          # Describe a pod, pre-fill 'nginx' in selection"
            echo "  kd -t deployment     # Describe a deployment (interactive selection)"
            echo "  kd -t service -q web # Describe a service, pre-fill 'web' in selection"
          }

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -h|--help)
                kd_help
                return 0
                ;;
              -q|--query)
                query="$2"
                shift 2
                ;;
              -t|--type)
                resource_type="$2"
                shift 2
                ;;
              --)
                shift
                kubectl_args+=("$@")
                break
                ;;
              *)
                kubectl_args+=("$1")
                shift
                ;;
            esac
          done

          local selected_resource=$(kubectl get $resource_type --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers |
            fzf --select-1 --query="$query")

          if [[ -n $selected_resource ]]; then
            local namespace=$(echo $selected_resource | awk '{print $1}')
            local resource_name=$(echo $selected_resource | awk '{print $2}')
            kubectl describe -n "$namespace" "$resource_type" "$resource_name" "''${kubectl_args[@]}"
          else
            echo "No $resource_type selected."
          fi
        }

        unalias kexec 2>/dev/null
        kexec() {
          local query=""
          local shell="/bin/sh"
          local kubectl_args=()

          kexec_help() {
            echo "Usage: kexec [OPTIONS] [-- KUBECTL_EXEC_ARGS]"
            echo
            echo "Execute a shell in a Kubernetes pod."
            echo
            echo "Options:"
            echo "  -q, --query QUERY    Pre-fill the pod selection search"
            echo "  -s, --shell SHELL    Specify the shell to use (default: /bin/sh)"
            echo "  -h, --help           Display this help message"
            echo
            echo "Examples:"
            echo "  kexec                            # Interactive pod and container selection"
            echo "  kexec -q nginx                   # Pre-fill 'nginx' in pod selection"
            echo "  kexec -s /bin/bash               # Use bash instead of sh"
            echo "  kexec -q backend -s /bin/bash    # Combine query and shell options"
            echo "  kexec -- env                     # Run 'env' command instead of interactive shell"
          }

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -h|--help)
                kexec_help
                return 0
                ;;
              -q|--query)
                query="$2"
                shift 2
                ;;
              -s|--shell)
                shell="$2"
                shift 2
                ;;
              --)
                shift
                kubectl_args+=("$@")
                break
                ;;
              *)
                kubectl_args+=("$1")
                shift
                ;;
            esac
          done

          local selected_pod=$(kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,POD:.metadata.name --no-headers |
            fzf --select-1 --query="$query")

          if [[ -n $selected_pod ]]; then
            local namespace=$(echo $selected_pod | awk '{print $1}')
            local pod_name=$(echo $selected_pod | awk '{print $2}')

            local containers=$(kubectl get pod -n "$namespace" "$pod_name" -o jsonpath='{.spec.containers[*].name}')
            local container_count=$(echo "$containers" | wc -w)

            if [[ $container_count -eq 1 ]]; then
              local container=$containers
            else
              local container=$(echo "$containers" | tr ' ' '\n' | fzf --select-1 --header="Select container")
            fi

            if [[ -n $container ]]; then
              echo "Executing into $namespace/$pod_name:$container"
              if [[ ''${#kubectl_args[@]} -eq 0 ]]; then
                kubectl exec -it -n "$namespace" "$pod_name" -c "$container" -- $shell
              else
                kubectl exec -it -n "$namespace" "$pod_name" -c "$container" -- "''${kubectl_args[@]}"
              fi
            else
              echo "No container selected."
            fi
          else
            echo "No pod selected."
          fi
        }

        unalias kpf 2>/dev/null
        kpf() {
          local query=""
          local resource_type="pod"
          local kubectl_args=()
          local ports=()

          kpf_help() {
            echo "Usage: kpf [OPTIONS] [LOCAL_PORT:REMOTE_PORT]..."
            echo
            echo "Port forward to a Kubernetes resource."
            echo
            echo "Options:"
            echo "  -q, --query QUERY    Pre-fill the resource selection search"
            echo "  -t, --type TYPE      Specify the resource type (default: pod)"
            echo "  -h, --help           Display this help message"
            echo
            echo "Arguments:"
            echo "  LOCAL_PORT:REMOTE_PORT  Specify the local port and remote port"
            echo "                          Multiple port pairs can be specified"
            echo
            echo "Examples:"
            echo "  kpf 8080:8080                    # Forward local port 8080 to port 8080 of a pod"
            echo "  kpf 8080:80 443:8443             # Forward multiple ports"
            echo "  kpf -q nginx 8080:80 443:443     # Forward to a pod, pre-fill 'nginx' in selection"
            echo "  kpf -t service 8080:80 443:443   # Forward to a service instead of a pod"
            echo "  kpf -t deployment 8080:8080      # Forward to a deployment instead of a pod"
          }

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -h|--help)
                kpf_help
                return 0
                ;;
              -q|--query)
                query="$2"
                shift 2
                ;;
              -t|--type)
                resource_type="$2"
                shift 2
                ;;
              *:*)
                ports+=("$1")
                shift
                ;;
              *)
                kubectl_args+=("$1")
                shift
                ;;
            esac
          done

          if [ ''${#ports[@]} -eq 0 ]; then
            echo "Error: At least one port mapping must be specified."
            kpf_help
            return 1
          fi

          local selected_resource=$(kubectl get $resource_type --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers |
            fzf --select-1 --query="$query")

          if [[ -n $selected_resource ]]; then
            local namespace=$(echo $selected_resource | awk '{print $1}')
            local resource_name=$(echo $selected_resource | awk '{print $2}')
            echo "Port forwarding to $resource_type $namespace/$resource_name:"
            for port in "''${ports[@]}"; do
              echo "  $port"
            done
            kubectl port-forward -n "$namespace" "$resource_type/$resource_name" "''${ports[@]}" "''${kubectl_args[@]}"
          else
            echo "No $resource_type selected."
          fi
        }
      '';
    };
  };
}
