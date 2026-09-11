-- ============================================================
-- Reembolsos Médicos — Esquema Supabase
-- Ejecutar completo en: Supabase Dashboard > SQL Editor > New query
-- ============================================================

create extension if not exists "pgcrypto";

-- --------------------------------------------------------------
-- Tabla: reembolsos_familiares
-- --------------------------------------------------------------
create table reembolsos_familiares (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  created_at timestamptz not null default now()
);

-- --------------------------------------------------------------
-- Tabla: reembolsos_gastos (el gasto médico original)
-- --------------------------------------------------------------
create table reembolsos_gastos (
  id uuid primary key default gen_random_uuid(),
  familiar_id uuid not null references reembolsos_familiares(id) on delete cascade,
  fecha date not null,
  tipo text not null check (tipo in ('consulta','medicamento','examen','otro')),
  descripcion text,
  monto_total numeric not null,
  created_at timestamptz not null default now()
);

-- --------------------------------------------------------------
-- Tabla: reembolsos_solicitudes (una o dos por gasto: isapre y/o seguro complementario)
-- --------------------------------------------------------------
create table reembolsos_solicitudes (
  id uuid primary key default gen_random_uuid(),
  gasto_id uuid not null references reembolsos_gastos(id) on delete cascade,
  entidad text not null check (entidad in ('isapre','seguro')),
  fecha_solicitud date not null,
  monto_solicitado numeric not null,
  estado text not null default 'solicitado' check (estado in ('solicitado','pagado','rechazado')),
  fecha_pago date,
  monto_pagado numeric,
  nota text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- SEGURIDAD (RLS) — igual que en el Libro de Cuotas: como esto
-- se publica en GitHub Pages, solo un usuario autenticado (tú)
-- puede leer/escribir.
-- ============================================================

alter table reembolsos_familiares enable row level security;
alter table reembolsos_gastos enable row level security;
alter table reembolsos_solicitudes enable row level security;

create policy "solo autenticados - reembolsos_familiares" on reembolsos_familiares
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "solo autenticados - reembolsos_gastos" on reembolsos_gastos
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "solo autenticados - reembolsos_solicitudes" on reembolsos_solicitudes
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================================
-- DESPUÉS DE CORRER ESTE SQL:
-- 1. Ve a Authentication > Users en el dashboard de Supabase
-- 2. "Add user" > "Create new user" con tu email y contraseña
-- 3. Activa "Auto Confirm User"
-- ============================================================
