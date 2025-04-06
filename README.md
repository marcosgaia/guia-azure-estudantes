 
#  Guia Azure para Estudantes - Como evitar cobranças em background

Este repositório mostra passo a passo como utilizar a conta gratuita do Azure para fins de estudo **sem cair em armadilhas de cobrança inesperada**.

---

## ⚠️ Aviso importante

Mesmo com benefícios de estudante, o Azure pode:
- Criar recursos automaticamente.
- Gerar cobranças em segundo plano (ex: Load Balancer, Storage, Key Vault).
- Cobrar se houver **cartão de crédito cadastrado**.

---

##  Objetivos do projeto

- Mostrar comandos para listar todos os recursos.
- Fornecer um script para desligar VMs ociosas.
- Ensinar como fazer uma limpeza total na assinatura.
- Alertar estudantes sobre cobranças ocultas.

---

##  Scripts úteis

### Desligar VMs ociosas automaticamente:

```bash
# desligar_ociosas.sh

duration=60
cpu_threshold=10
vms=$(az vm list --show-details --query "[?powerState=='VM running']" -o json)

for row in $(echo "${vms}" | jq -c '.[]'); do
  vm_name=$(echo "$row" | jq -r '.name')
  rg_name=$(echo "$row" | jq -r '.resourceGroup')
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
    echo "→ Ociosa! Desligando $vm_name..."
    az vm deallocate --name "$vm_name" --resource-group "$rg_name"
  else
    echo "→ Em uso, mantendo ligada."
  fi
done



lustração do Projeto
A imagem abaixo representa o cenário: estudante estudando tarde da noite e o Azure cobrando em segundo plano.


 Dicas de Limpeza e Prevenção
Execute comandos como:

bash
Copiar
Editar
az vm list --show-details --query "[?powerState=='VM running'].[name, resourceGroup]" -o table
az network lb list -o table
az disk list -o table
az keyvault list -o table
az storage account list -o table
Delete manualmente com az resource delete --ids ....

Cancele a assinatura.

⚠️ Cartão de crédito não pode ser removido se estiver atrelado.

Abra ticket com suporte se necessário.

🧠 Conclusão
Sempre haverá algum custo, mesmo que mínimo.

A conta de estudante não é 100% gratuita na prática.

Estude, teste, e limpe tudo depois.

Considere criar alertas de cobrança no portal do Azure.

🐙 Compartilhe!
Você pode:


Criar um post no blog ou redes sociais.

Contribuir com melhorias aqui no repositório.

Feito por Marcos Gaia com base em uma experiência real para ajudar outros estudantes. 


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


