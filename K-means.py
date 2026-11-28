import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

# cargar los datos que exportamos de sql server
df = pd.read_csv('clientes_kmeans.csv')
print("Clientes cargados:", len(df))
print(df.head())

# seleccion de variables numericas y escalado
cols = ['MontoTotal', 'FrecuenciaOrdenes', 'TicketPromedio', 'VisitasWeb', 'ConversionesWeb']
X = df[cols].astype(float)

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# probar valores de k del 2 al 7
ks = range(2, 8)
inercias = []
siluetas = []

print("\nResultados por valor de k:")
for k in ks:
    km = KMeans(n_clusters=k, random_state=42, n_init=20)
    etiquetas = km.fit_predict(X_scaled)
    inercia = km.inertia_
    sil = silhouette_score(X_scaled, etiquetas)
    inercias.append(inercia)
    siluetas.append(sil)
    print(f"k={k} -> inercia: {inercia:.2f}, silueta: {sil:.4f}")

# graficas de codo y silueta
fig, axes = plt.subplots(1, 2, figsize=(12, 4.5), dpi=200)

axes[0].plot(list(ks), inercias, marker='o', linewidth=2, color='#1f4e79')
axes[0].set_title('Método del codo', fontsize=11, fontweight='bold')
axes[0].set_xlabel('Número de grupos (k)')
axes[0].set_ylabel('Inercia')
axes[0].grid(True, linestyle='--', alpha=0.5)

axes[1].plot(list(ks), siluetas, marker='s', linewidth=2, color='#2e7d32')
axes[1].set_title('Coeficiente de silueta', fontsize=11, fontweight='bold')
axes[1].set_xlabel('Número de grupos (k)')
axes[1].set_ylabel('Silueta')
axes[1].grid(True, linestyle='--', alpha=0.5)

plt.tight_layout()
plt.savefig('grafica_codo_silueta.png', dpi=300)
plt.show()

# seleccionar el mejor k entre 3 y 4 segun la silueta
candidatos = [3, 4]
k_optimo = max(candidatos, key=lambda k: siluetas[k - 2])
sil_optimo = siluetas[k_optimo - 2]
print(f"\nMejor k elegido: {k_optimo} (silueta: {sil_optimo:.4f})")

kmeans_final = KMeans(n_clusters=k_optimo, random_state=42, n_init=20)
df['ClusterNum'] = kmeans_final.fit_predict(X_scaled)

# ordenar grupos de mayor a menor monto promedio y asignar nombres
resumen_raw = df.groupby('ClusterNum')[cols].mean().sort_values(by='MontoTotal', ascending=False)

nombres_por_k = {
    3: ['Alto valor', 'Valor medio', 'Ocasionales'],
    4: ['Clientes VIP', 'Frecuentes', 'Activos en web', 'Ocasionales']
}
lista_nombres = nombres_por_k.get(k_optimo, [f'Grupo {i+1}' for i in range(k_optimo)])

mapa_nombres = {cluster_id: lista_nombres[idx] for idx, cluster_id in enumerate(resumen_raw.index)}
df['SegmentoAnalitico'] = df['ClusterNum'].map(mapa_nombres)

# resumen de promedios por segmento
resumen = df.groupby('SegmentoAnalitico').agg(
    Clientes=('ClienteID', 'count'),
    MontoProm=('MontoTotal', 'mean'),
    OrdenesProm=('FrecuenciaOrdenes', 'mean'),
    TicketProm=('TicketPromedio', 'mean'),
    VisitasProm=('VisitasWeb', 'mean'),
    ConversionesProm=('ConversionesWeb', 'mean')
).sort_values(by='MontoProm', ascending=False)

print("\nResumen por segmento:")
print(resumen.round(2).to_string())

# dispersion de visitas web vs monto total
plt.figure(figsize=(8.5, 5), dpi=200)
colores = ['#1f4e79', '#2e7d32', '#d97706', '#c62828']
for idx, seg in enumerate(resumen.index):
    sub = df[df['SegmentoAnalitico'] == seg]
    plt.scatter(
        sub['VisitasWeb'], sub['MontoTotal'],
        label=f"{seg} (n={len(sub)})",
        color=colores[idx % len(colores)], s=65, alpha=0.85, edgecolors='white', linewidth=0.5
    )

plt.title(f'Segmentación de clientes con K-means (k={k_optimo})', fontsize=12, fontweight='bold')
plt.xlabel('Visitas web (2024)')
plt.ylabel('Monto total de compras (USD)')
plt.legend(title='Segmento')
plt.grid(True, linestyle='--', alpha=0.4)
plt.tight_layout()
plt.savefig('grafica_clusters_kmeans.png', dpi=300)
plt.show()

# exportar archivo sql para actualizar la tabla en sql server
with open('update_dim_cliente_kmeans.sql', 'w', encoding='utf-8') as f:
    f.write("USE DW_AndinaRetail;\nGO\n\n")
    for _, row in df.iterrows():
        cid = str(row['ClienteID']).strip().replace("'", "''")
        seg = str(row['SegmentoAnalitico']).strip().replace("'", "''")
        f.write(f"UPDATE dw.Dim_Cliente SET SegmentoAnalitico = '{seg}' WHERE ClienteID = '{cid}' AND EsActual = 1;\n")
    f.write("\nGO\n")
    f.write("SELECT SegmentoAnalitico, COUNT(*) AS CantidadClientes FROM dw.Dim_Cliente WHERE EsActual = 1 GROUP BY SegmentoAnalitico ORDER BY CantidadClientes DESC;\n")

print("\nListo, se generaron las graficas y el script .sql")
