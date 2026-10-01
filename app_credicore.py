import pandas as pd
import pyodbc
import streamlit as st

st.set_page_config(page_title="ERP CrediCore", layout="centered")
st.title("🏦 CrediCore - Módulo de Caja")
st.markdown("Interfaz conectada directamente al motor transaccional de SQL Server")

# Configuración de Conexión
SERVER = "192.168.1.223"
DATABASE = "CrediCoreDB"
USERNAME = "sa"
PASSWORD = "Elirosales516!"

conn_str = f"DRIVER={{SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}"

# 1. Leer la Vista Segura
st.subheader("Estado de Cuenta (Vista Segura)")
try:
  conn = pyodbc.connect(conn_str)
  query = "SELECT * FROM Operaciones.vw_AtencionAlCliente"
  df = pd.read_sql(query, conn)
  st.dataframe(df, use_container_width=True)
  conn.close()
except Exception as e:
  st.error(f"Error de conexión a la BD: {e}")

st.divider()

# 2. Formulario para ejecutar el Procedimiento Almacenado
st.subheader("Procesar Pago de Cuota")
with st.form("form_pago", clear_on_submit=False):
  id_credito = st.number_input(
      "Número de Crédito (ID)", min_value=1, step=1
  )
  monto_pago = st.number_input(
      "Monto a Abonar (Q)", min_value=1.0, step=100.0
  )
  btn_pagar = st.form_submit_button("Ejecutar Transacción")

  if btn_pagar:
    try:
      conn = pyodbc.connect(conn_str)
      cursor = conn.cursor()
      # Invocamos el SP con sus parámetros
      cursor.execute(
          f"EXEC Operaciones.SP_ProcesarPago @IdCredito = {id_credito},"
          f" @MontoAbono = {monto_pago}"
      )
      conn.commit()
      conn.close()

      st.success(
          f"¡Pago de Q{monto_pago:.2f} procesado con éxito para el Crédito ID"
          f" {id_credito}!"
      )
    except Exception as e:
      # Captura el RAISERROR programado en el TRY...CATCH de SQL
      st.error(f"Transacción Rechazada por el Motor: {e}")