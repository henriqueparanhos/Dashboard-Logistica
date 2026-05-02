# 📦 Dashboard Logístico — Power BI + DAX + HTML Interativo

Projeto de análise operacional de entregas construído inteiramente em **Power BI Desktop**, com modelo semântico DAX avançado e um dashboard HTML interativo renderizado nativamente dentro do relatório — sem dependências externas, sem JavaScript libraries, sem servidores.

Link para visualização do projeto publicado: [Ver Dashboard no Power BI](https://app.powerbi.com/view?r=eyJrIjoiYWU5NzQ4NWEtOWI2Yi00NTc0LTgzZjktZGQ5YjIzYjk1OGY4IiwidCI6IjJiNThhYTg0LTY3ZGItNDkxOC1hMTZjLTRjYjI3Nzk3NDBiZCJ9)
---

## Estrutura do Modelo

O modelo contém 3 tabelas principais:

| Tabela | Colunas | Descrição |
|---|---|---|
| `01_Entregas` | 13 | Tabela fato principal: pedidos, datas, transportadora, região, SLA, status e NPS |
| `02_KPIs_SLA` | 12 | Indicadores de nível de serviço por período |
| `03_Ranking_Transportadoras` | 9 | Consolidado de performance por transportadora |

---

## 📐 Medidas DAX

Todas as 19 medidas foram criadas na tabela `01_Entregas`, organizadas em três camadas:

### Métricas operacionais
| Medida | Descrição |
|---|---|
| `Total de Entregas` | Contagem total de registros |
| `Entregas no Prazo` | Entregas com status "Entregue no Prazo" |
| `Entregas Fora do Prazo` | Entregas com status "Entregue com Atraso" |
| `Entregas Extraviadas` | Entregas com status "Extraviado" |
| `SLA Médio (dias)` | Média de dias de SLA |
| `SLA Máximo (dias)` | Maior SLA registrado |
| `SLA Mínimo (dias)` | Menor SLA registrado |
| `NPS Médio` | Média geral do NPS |
| `NPS Médio por Região` | NPS médio sensível ao filtro de região |
| `NPS Médio por Transportadora` | NPS médio sensível ao filtro de transportadora |
| `NPS x SLA Médio` | Razão NPS ÷ SLA — satisfação por dia de entrega |
| `Total de Entregas por Região` | Total sensível ao filtro de região |
| `Regiões por Transportadora` | Lista de regiões atendidas por transportadora |

### Camada JSON (alimentam o dashboard HTML)
| Medida | Descrição |
|---|---|
| `_JSON Mensal` | Array com totais por mês/ano — usa `ADDCOLUMNS + GROUPBY + SUMX(CURRENTGROUP())` |
| `_JSON Transportadora` | Array com totais e SLA médio por transportadora |
| `_JSON Tabela` | Array completo de registros com todos os campos (1.000 linhas) |
| `_JSON RegiaoCanal` | Array com totais por combinação Região × Transportadora (máx. 99) |

### Camada de apresentação
| Medida | Descrição |
|---|---|
| `HTML Dashboard Final` | Retorna HTML/CSS/JS completo (~140KB) para renderização no visual HTML Content |

---

## Dashboard HTML Interativo

O dashboard é gerado inteiramente por DAX como uma string HTML e renderizado pelo visual **HTML Content** (AppSource). Não usa bibliotecas externas — todos os gráficos são SVG puros construídos via `createElement + setAttribute`.

### Componentes

**Cards KPI** — 6 indicadores com valores em tempo real do contexto de filtro:
Total de Entregas · No Prazo · Fora do Prazo · Extraviadas · SLA Médio · NPS Médio

**Gráfico de Barras Adaptativo**
- Modo `Todos`: exibe o acumulado mensal (12 barras, Jan–Dez)
- Modo mês filtrado: exibe o volume diário dentro do mês selecionado (ex: 31 barras para Janeiro)
- Tooltip ao hover com mês/dia e quantidade
- Título do gráfico muda dinamicamente: *"Entregas por Mês"* → *"Entregas por Dia - Jan"*

**Donut Chart por Região**
- SVG calculado com arcos trigonométricos via JavaScript
- Percentuais inline nas fatias maiores que 6%
- Legenda com total de entregas por região
- Total geral exibido no centro do anel

**Painel Resumo Operacional** (calculado dinamicamente pelo filtro ativo)
- Barras de progresso: % No Prazo / Fora do Prazo / Extraviadas
- NPS médio do período filtrado
- Top transportadora e top região com contagens

**Tabela Paginada**
- 10 registros por página, navegação por botões
- Coluna Status com cor contextual (verde / vermelho / laranja)
- Badge NPS colorido por faixa (≥9 verde · ≥7 amarelo · <7 vermelho)
- Contador de registros e páginas

**Filtro de Período**
- 13 botões: Todos + Jan a Dez
- Filtra simultaneamente: gráfico de barras, resumo operacional e tabela
- Botão ativo destacado em amarelo `#F2C94C`

**Exportação CSV**
- Exporta os dados do período filtrado em `.csv`
- Campos: id, data, transportadora, regiao, status, nps

### Tema visual
```
Background:  #1A1A2E
Painéis:     #16213E
Bordas:      #1E3A6E
Accent:      #F2C94C  (amarelo)
Texto:       #F0F0F0  (branco, font-weight 600–800)
```

--=

##  Como usar

1. Abra o arquivo `.pbix` no **Power BI Desktop**
2. Instale o visual **HTML Content** pelo AppSource (gratuito)
3. Adicione o visual ao relatório e arraste a medida `HTML Dashboard Final` para o campo **HTML Content**
4. Redimensione o visual para pelo menos **900 × 650 px**
5. Para atualizar após mudanças no modelo: clique fora do visual e clique nele novamente, ou delete e readicione

---

## Arquivos

```
Dashboard - Logística.pbix       — Arquivo principal do Power BI
projeto05_logistica.sql - Base de dados em MySQL
sla_entregas_portfolio.xlsx - Excel para limpeza e organização dos dados
README.md — Este documento
```
