 

---

## 📄 `desligar_ociosas.sh`

```bash
#!/bin/bash

# desligar_ociosas.sh
# Script para desligar VMs ociosas com uso de CPU abaixo de 10%

duration=60
cpu_threshold=10

echo "🔎 Buscando VMs em execução..."

vms=$(az vm list --show-details --query "[?powerState=='VM running']" -o json)

for row in $(echo "${vms}" | jq -c '.[]'); do
  vm_name=$(echo "$row" | jq -r '.name')
  rg_name=$(echo "$row" | jq -r '.resourceGroup')

  echo "🧠 Verificando VM: $vm_name..."

  avg_cpu=$(az monitor metrics list \
    --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rg_name/providers/Microsoft.Compute/virtualMachines/$vm_name" \
    --metric "Percentage CPU" \
    --interval PT1M \
    --aggregation Average \
    --orderby "timestamp desc" \
    --duration PT${duration}M \
    --query "value[0].timeseries[0].data[*].average" -o tsv | \
    awk '{ total += $1; count++ } END { if (count > 0) print total/count; else print 0 }')

  echo "→ Média de CPU: ${avg_cpu}%"

  if (( $(echo "$avg_cpu < $cpu_threshold" | bc -l) )); then
    echo "⛔ Ociosa! Desligando $vm_name..."
    az vm deallocate --name "$vm_name" --resource-group "$rg_name"
  else
    echo "✅ Em uso, mantendo ligada."
  fi
done
