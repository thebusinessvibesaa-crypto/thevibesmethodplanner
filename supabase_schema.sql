-- ============================================================================
-- THE VIBES METHOD OS - SUPABASE SCHEMA COMPLETO
-- ============================================================================
-- Versión: 1.1
-- Última actualización: Abril 2026 (corregido)
-- Propósito: Arquitectura Multitenant para VPLASH LLC
-- ============================================================================

-- PASO 1: HABILITAR EXTENSIONES NECESARIAS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLAS CORE: AUTENTICACIÓN Y USUARIOS
-- ============================================================================

-- Tabla: usuarios (vinculada con auth.users de Supabase)
CREATE TABLE public.usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nombre_completo TEXT,
  rol TEXT NOT NULL CHECK (rol IN ('ceo', 'coo', 'trafficer', 'alumno', 'asistente')),
  empresa_id UUID,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Tabla: empresas (Multitenant)
CREATE TABLE public.empresas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre TEXT NOT NULL UNIQUE,
  plan TEXT CHECK (plan IN ('starter', 'pro', 'enterprise')) DEFAULT 'pro',
  fecha_suscripcion DATE DEFAULT CURRENT_DATE,
  fecha_renovacion DATE,
  activa BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Agregar constraint a usuarios
ALTER TABLE public.usuarios 
ADD CONSTRAINT fk_usuarios_empresa 
FOREIGN KEY (empresa_id) REFERENCES public.empresas(id) ON DELETE SET NULL;

-- ============================================================================
-- TABLA CORE: LANZAMIENTOS (The Launch Engine)
-- ============================================================================

CREATE TABLE public.lanzamientos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  nombre_lanzamiento TEXT NOT NULL,
  fase_anual INTEGER NOT NULL CHECK (fase_anual >= 1 AND fase_anual <= 4),
  pilar_metodo TEXT NOT NULL CHECK (pilar_metodo IN ('identidad', 'sistemas', 'legado')),
  fecha_apertura DATE NOT NULL,
  ticket_precio NUMERIC(10,2) NOT NULL,
  meta_unidades INTEGER NOT NULL,
  revenue_proyectado NUMERIC(14,2) GENERATED ALWAYS AS (ticket_precio * meta_unidades) STORED,
  presupuesto_ads_asignado NUMERIC(12,2) NOT NULL,
  roas_meta NUMERIC(5,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('planificacion', 'precalentamiento', 'lanzamiento', 'entrega', 'finalizado', 'pausado_bajo_roas')),
  ceo_aprobada BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  UNIQUE(empresa_id, nombre_lanzamiento)
);

-- Índices para lanzamientos
CREATE INDEX idx_lanzamientos_empresa ON public.lanzamientos(empresa_id);
CREATE INDEX idx_lanzamientos_status ON public.lanzamientos(status);
CREATE INDEX idx_lanzamientos_fecha ON public.lanzamientos(fecha_apertura);

-- ============================================================================
-- TABLA: KPI DAILY TRACKING (Datos inyectados por Make.com)
-- ============================================================================

CREATE TABLE public.kpi_daily_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lanzamiento_id UUID NOT NULL REFERENCES public.lanzamientos(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  gasto_hoy NUMERIC(10,2),
  leads_hoy INTEGER,
  ventas_hoy INTEGER,
  revenue_hoy NUMERIC(12,2),
  roas_real NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN gasto_hoy = 0 THEN 0
      ELSE revenue_hoy / gasto_hoy
    END
  ) STORED,
  cpl_real NUMERIC(8,2) GENERATED ALWAYS AS (
    CASE 
      WHEN leads_hoy = 0 THEN 0
      ELSE gasto_hoy / leads_hoy
    END
  ) STORED,
  fuente_datos TEXT CHECK (fuente_datos IN ('meta', 'hotmart', 'youtube', 'stripe')),
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(lanzamiento_id, fecha, fuente_datos)
);

-- Índices para performance (crucial para queries en tiempo real)
CREATE INDEX idx_kpi_tracking_lanzamiento ON public.kpi_daily_tracking(lanzamiento_id);
CREATE INDEX idx_kpi_tracking_fecha ON public.kpi_daily_tracking(fecha);
CREATE INDEX idx_kpi_tracking_composite ON public.kpi_daily_tracking(lanzamiento_id, fecha DESC);

-- NOTA: Para escalabilidad a millones de registros, considera particionamiento por fecha:
-- ALTER TABLE public.kpi_daily_tracking PARTITION BY RANGE (fecha);

-- ============================================================================
-- TABLA: SMART CONTENT INVENTORY
-- ============================================================================

CREATE TABLE public.smart_content_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lanzamiento_id UUID NOT NULL REFERENCES public.lanzamientos(id) ON DELETE CASCADE,
  titulo_contenido TEXT NOT NULL,
  tipo_contenido TEXT NOT NULL CHECK (tipo_contenido IN ('video_master', 'reel', 'blog', 'email', 'carrusel', 'tweet', 'otro')),
  estado TEXT NOT NULL CHECK (estado IN ('draft', 'pendiente_revision', 'aprobado', 'scheduled', 'published', 'archived')),
  url_contenido TEXT,
  url_original TEXT, -- Link del video master de YouTube
  transcripcion TEXT,
  palabra_clave_principal TEXT,
  engagement_rate NUMERIC(5,2) DEFAULT 0,
  fecha_publicacion DATE,
  responsable_id UUID REFERENCES public.usuarios(id),
  fecha_entrega_estimada DATE,
  notas_ceo TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  UNIQUE(lanzamiento_id, titulo_contenido, tipo_contenido)
);

CREATE INDEX idx_smart_content_lanzamiento ON public.smart_content_inventory(lanzamiento_id);
CREATE INDEX idx_smart_content_estado ON public.smart_content_inventory(estado);
CREATE INDEX idx_smart_content_responsable ON public.smart_content_inventory(responsable_id);

-- ============================================================================
-- TABLA: SOP LIBRARY (Standard Operating Procedures)
-- ============================================================================

CREATE TABLE public.sop_library (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lanzamiento_id UUID NOT NULL REFERENCES public.lanzamientos(id) ON DELETE CASCADE,
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  titulo_tarea TEXT NOT NULL,
  descripcion TEXT,
  responsable_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE RESTRICT,
  fecha_deadline DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pendiente', 'en_progreso', 'completada', 'retrasada', 'cancelada')),
  prioridad TEXT CHECK (prioridad IN ('baja', 'media', 'alta', 'critica')),
  fecha_completacion DATE,
  notificacion_whatsapp_enviada BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_sop_responsable ON public.sop_library(responsable_id);
CREATE INDEX idx_sop_deadline ON public.sop_library(fecha_deadline);
CREATE INDEX idx_sop_status ON public.sop_library(status);
CREATE INDEX idx_sop_lanzamiento ON public.sop_library(lanzamiento_id);

-- ============================================================================
-- TABLA: BIOHACKING & WELLNESS (KPI Personal de CEO)
-- ============================================================================

CREATE TABLE public.biohacking_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  horas_sueno NUMERIC(4,2),
  energia_morning INTEGER CHECK (energia_morning >= 1 AND energia_morning <= 10),
  energia_afternoon INTEGER CHECK (energia_afternoon >= 1 AND energia_afternoon <= 10),
  energia_evening INTEGER CHECK (energia_evening >= 1 AND energia_evening <= 10),
  energia_promedio NUMERIC(4,2) GENERATED ALWAYS AS (
    (COALESCE(energia_morning, 0) + COALESCE(energia_afternoon, 0) + COALESCE(energia_evening, 0)) / 3.0
  ) STORED,
  exposicion_luz_solar BOOLEAN DEFAULT false,
  suplementacion_completada BOOLEAN DEFAULT false,
  meditacion_minutos INTEGER DEFAULT 0,
  tarea_unica_completada BOOLEAN DEFAULT false,
  notas TEXT,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(usuario_id, fecha)
);

CREATE INDEX idx_biohacking_usuario ON public.biohacking_log(usuario_id);
CREATE INDEX idx_biohacking_fecha ON public.biohacking_log(fecha);

-- ============================================================================
-- TABLA: CORRELACIÓN ENERGÍA vs CONVERSIONES
-- ============================================================================

CREATE TABLE public.energy_sales_correlation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lanzamiento_id UUID NOT NULL REFERENCES public.lanzamientos(id) ON DELETE CASCADE,
  usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  energia_promedio NUMERIC(4,2),
  conversion_tasa NUMERIC(5,2),
  llamadas_completadas INTEGER DEFAULT 0,
  notas_analista TEXT,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(lanzamiento_id, usuario_id, fecha)
);

CREATE INDEX idx_energy_sales_correlacion ON public.energy_sales_correlation(lanzamiento_id, fecha);

-- ============================================================================
-- TABLA: AUDIT LOG (Trazabilidad total)
-- ============================================================================

CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES public.usuarios(id) ON DELETE SET NULL,
  tabla_afectada TEXT NOT NULL,
  registro_id UUID,
  accion TEXT NOT NULL CHECK (accion IN ('INSERT', 'UPDATE', 'DELETE')),
  valores_antiguos JSONB,
  valores_nuevos JSONB,
  timestamp TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_audit_empresa ON public.audit_log(empresa_id);
CREATE INDEX idx_audit_tabla ON public.audit_log(tabla_afectada);
CREATE INDEX idx_audit_timestamp ON public.audit_log(timestamp DESC);

-- ============================================================================
-- TABLA: PLANTILLA ENUM FLEXIBLE (para future-proofing)
-- ============================================================================

CREATE TABLE public.launch_status_types (
  id SERIAL PRIMARY KEY,
  status_nombre TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO public.launch_status_types (status_nombre, descripcion) VALUES
  ('planificacion', 'En fase de planificación'),
  ('precalentamiento', 'Pre-lanzamiento, calentando audiencia'),
  ('lanzamiento', 'Puertas abiertas activas'),
  ('entrega', 'Entrega de contenido a alumnos'),
  ('finalizado', 'Lanzamiento cerrado'),
  ('pausado_bajo_roas', 'Pausado automáticamente por bajo ROAS');

-- ============================================================================
-- TABLA: NOTIFICACIONES (para WhatsApp alerts)
-- ============================================================================

CREATE TABLE public.notificaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  tipo_notificacion TEXT NOT NULL CHECK (tipo_notificacion IN ('alerta_roas', 'venta_realizada', 'tarea_vencida', 'contenido_aprobado', 'insight_energia')),
  titulo TEXT NOT NULL,
  mensaje TEXT,
  enlace_referencia UUID,
  enviado_por TEXT CHECK (enviado_por IN ('email', 'whatsapp', 'in_app')),
  leido BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now(),
  enviado_at TIMESTAMP
);

CREATE INDEX idx_notificaciones_usuario ON public.notificaciones(usuario_id);
CREATE INDEX idx_notificaciones_leido ON public.notificaciones(leido);

-- ============================================================================
-- TRIGGERS: AUTOMATIZACIÓN DE AUDITORÍA
-- ============================================================================

-- Función para registrar cambios en lanzamientos
CREATE OR REPLACE FUNCTION public.audit_lanzamientos_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    INSERT INTO public.audit_log (
      empresa_id, usuario_id, tabla_afectada, registro_id, accion, 
      valores_antiguos, valores_nuevos
    ) VALUES (
      NEW.empresa_id,
      auth.uid(),
      'lanzamientos',
      NEW.id,
      'UPDATE',
      to_jsonb(OLD),
      to_jsonb(NEW)
    );
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_log (
      empresa_id, usuario_id, tabla_afectada, registro_id, accion, valores_nuevos
    ) VALUES (
      NEW.empresa_id,
      auth.uid(),
      'lanzamientos',
      NEW.id,
      'INSERT',
      to_jsonb(NEW)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_audit_lanzamientos
  AFTER INSERT OR UPDATE ON public.lanzamientos
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_lanzamientos_changes();

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_lanzamientos_updated_at
  BEFORE UPDATE ON public.lanzamientos
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_smart_content_updated_at
  BEFORE UPDATE ON public.smart_content_inventory
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_usuarios_updated_at
  BEFORE UPDATE ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_empresas_updated_at
  BEFORE UPDATE ON public.empresas
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_sop_library_updated_at
  BEFORE UPDATE ON public.sop_library
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - SEGURIDAD MULTITENANT
-- ============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lanzamientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kpi_daily_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_content_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sop_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biohacking_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.energy_sales_correlation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.launch_status_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;

-- POLÍTICA 1: USUARIOS solo ven su propia información
CREATE POLICY "Usuarios ven solo sus datos" ON public.usuarios
  FOR SELECT
  USING (auth.uid() = id OR 
         EXISTS (
           SELECT 1 FROM public.usuarios u1 
           WHERE u1.id = auth.uid() AND u1.rol = 'ceo'
         ));

-- POLÍTICA 2: EMPRESAS - Solo usuarios de esa empresa
CREATE POLICY "Usuarios solo ven su empresa" ON public.empresas
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE usuarios.id = auth.uid() AND usuarios.empresa_id = empresas.id
  ));

-- POLÍTICA 3: LANZAMIENTOS - Solo usuarios de la empresa
CREATE POLICY "Lanzamientos visible para empresa" ON public.lanzamientos
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE usuarios.id = auth.uid() AND usuarios.empresa_id = lanzamientos.empresa_id
  ));

CREATE POLICY "Lanzamientos editable por CEO" ON public.lanzamientos
  FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE usuarios.id = auth.uid() AND usuarios.rol = 'ceo' AND usuarios.empresa_id = lanzamientos.empresa_id
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE usuarios.id = auth.uid() AND usuarios.rol = 'ceo' AND usuarios.empresa_id = lanzamientos.empresa_id
  ));

-- POLÍTICA 4: KPI TRACKING - Solo usuarios de la misma empresa ven el tracking
CREATE POLICY "KPI visible para equipo" ON public.kpi_daily_tracking
  FOR SELECT
  USING (EXISTS (
    SELECT 1
    FROM public.usuarios u
    INNER JOIN public.lanzamientos l ON l.empresa_id = u.empresa_id
    WHERE u.id = auth.uid()
      AND l.id = kpi_daily_tracking.lanzamiento_id
  ));

-- POLÍTICA 5: SMART CONTENT - Equipo de la empresa puede ver, responsable/CEO edita
CREATE POLICY "Contenido visible para empresa" ON public.smart_content_inventory
  FOR SELECT
  USING (EXISTS (
    SELECT 1
    FROM public.usuarios u
    INNER JOIN public.lanzamientos l ON l.empresa_id = u.empresa_id
    WHERE u.id = auth.uid()
      AND l.id = smart_content_inventory.lanzamiento_id
  ));

CREATE POLICY "Contenido editable por responsable" ON public.smart_content_inventory
  FOR UPDATE
  USING (
    responsable_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.usuarios u
      INNER JOIN public.lanzamientos l ON l.empresa_id = u.empresa_id
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
        AND l.id = smart_content_inventory.lanzamiento_id
    )
  )
  WITH CHECK (
    responsable_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.usuarios u
      INNER JOIN public.lanzamientos l ON l.empresa_id = u.empresa_id
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
        AND l.id = smart_content_inventory.lanzamiento_id
    )
  );

-- POLÍTICA 6: SOP LIBRARY - Equipo de la empresa ve tareas; responsable o CEO actualiza
CREATE POLICY "SOP visible para empresa" ON public.sop_library
  FOR SELECT
  USING (EXISTS (
    SELECT 1
    FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.empresa_id = sop_library.empresa_id
  ));

CREATE POLICY "SOP editable por responsable o CEO" ON public.sop_library
  FOR UPDATE
  USING (
    responsable_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
        AND u.empresa_id = sop_library.empresa_id
    )
  )
  WITH CHECK (
    responsable_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
        AND u.empresa_id = sop_library.empresa_id
    )
  );

-- POLÍTICA 7: BIOHACKING - Solo usuario propietario o CEO
CREATE POLICY "Biohacking solo usuario propietario" ON public.biohacking_log
  FOR SELECT
  USING (
    usuario_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
    )
  );

-- POLÍTICA 8: ENERGY SALES - Solo usuarios de la misma empresa
CREATE POLICY "Energy sales visible para empresa" ON public.energy_sales_correlation
  FOR SELECT
  USING (EXISTS (
    SELECT 1
    FROM public.usuarios u
    INNER JOIN public.lanzamientos l ON l.empresa_id = u.empresa_id
    WHERE u.id = auth.uid()
      AND l.id = energy_sales_correlation.lanzamiento_id
  ));

-- POLÍTICA 9: AUDIT LOG - Solo CEO acceso
CREATE POLICY "Audit log visible para CEO" ON public.audit_log
  FOR SELECT
  USING (EXISTS (
    SELECT 1
    FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.rol = 'ceo'
      AND u.empresa_id = audit_log.empresa_id
  ));

-- POLÍTICA 10: launch_status_types - catálogo visible para clientes
CREATE POLICY "Launch status types visible para clientes" ON public.launch_status_types
  FOR SELECT
  USING (true);

-- POLÍTICA 11: NOTIFICACIONES - Solo destinatario
CREATE POLICY "Notificaciones solo para destinatario" ON public.notificaciones
  FOR SELECT
  USING (usuario_id = auth.uid());

-- ============================================================================
-- VISTAS ÚTILES PARA DASHBOARDS
-- ============================================================================

-- Vista: Dashboard de CEO (resumen ejecutivo)
CREATE OR REPLACE VIEW vw_dashboard_ceo AS
SELECT 
  l.id,
  l.nombre_lanzamiento,
  l.status,
  l.meta_unidades,
  COUNT(DISTINCT kpi.fecha) as dias_registrados,
  SUM(kpi.ventas_hoy) as ventas_totales,
  SUM(kpi.gasto_hoy) as gasto_total,
  AVG(kpi.roas_real) as roas_promedio,
  l.roas_meta,
  CASE 
    WHEN AVG(kpi.roas_real) >= l.roas_meta * 0.7 THEN 'Verde'
    WHEN AVG(kpi.roas_real) >= l.roas_meta * 0.5 THEN 'Amarillo'
    ELSE 'Rojo'
  END as semaforo_roas,
  (SUM(kpi.ventas_hoy)::FLOAT / l.meta_unidades * 100)::NUMERIC(5,2) as avance_meta_pct
FROM public.lanzamientos l
LEFT JOIN public.kpi_daily_tracking kpi ON l.id = kpi.lanzamiento_id
GROUP BY l.id, l.nombre_lanzamiento, l.status, l.meta_unidades, l.roas_meta;

-- Vista: Tareas pendientes por responsable
CREATE OR REPLACE VIEW vw_tareas_pendientes AS
SELECT 
  u.nombre_completo,
  COUNT(CASE WHEN sop.status = 'pendiente' THEN 1 END) as tareas_pendientes,
  COUNT(CASE WHEN sop.status = 'retrasada' THEN 1 END) as tareas_retrasadas,
  COUNT(CASE WHEN sop.status = 'en_progreso' THEN 1 END) as en_progreso,
  MIN(sop.fecha_deadline) as proxima_fecha_vencimiento
FROM public.usuarios u
LEFT JOIN public.sop_library sop ON u.id = sop.responsable_id AND sop.status IN ('pendiente', 'en_progreso', 'retrasada')
WHERE u.rol != 'alumno'
GROUP BY u.id, u.nombre_completo;

-- Vista: Correlación Energía vs Conversión (para insights de CEO)
CREATE OR REPLACE VIEW vw_energia_conversiones AS
SELECT 
  DATE(bio.fecha) as fecha,
  bio.energia_promedio,
  AVG(esc.conversion_tasa) as conversion_promedio,
  STRING_AGG(esc.notas_analista, ' | ') as insight
FROM public.biohacking_log bio
LEFT JOIN public.energy_sales_correlation esc ON 
  bio.usuario_id = esc.usuario_id AND bio.fecha = esc.fecha
WHERE bio.usuario_id = auth.uid() -- Se filtrará por sesión
GROUP BY DATE(bio.fecha), bio.energia_promedio
ORDER BY bio.fecha DESC;

-- Vista: Contenido pendiente de aprobación
CREATE OR REPLACE VIEW vw_contenido_pendiente_aprobacion AS
SELECT 
  sci.id,
  sci.titulo_contenido,
  sci.tipo_contenido,
  u.nombre_completo as responsable,
  sci.fecha_entrega_estimada,
  CASE 
    WHEN sci.fecha_entrega_estimada < CURRENT_DATE THEN 'Retrasado'
    WHEN sci.fecha_entrega_estimada <= CURRENT_DATE + INTERVAL '3 days' THEN 'Urgente'
    ELSE 'En Plazo'
  END as urgencia,
  l.nombre_lanzamiento
FROM public.smart_content_inventory sci
INNER JOIN public.usuarios u ON sci.responsable_id = u.id
INNER JOIN public.lanzamientos l ON sci.lanzamiento_id = l.id
WHERE sci.estado = 'pendiente_revision'
ORDER BY sci.fecha_entrega_estimada ASC;

-- ============================================================================
-- DATOS DE EJEMPLO (comentados - descomentar para testing)
-- ============================================================================

/*
-- Insertar empresa
INSERT INTO public.empresas (nombre, plan) VALUES 
  ('VPLASH LLC', 'enterprise')
RETURNING id as empresa_id;

-- Insertar usuarios (después de crear en Auth)
-- Reemplazar UUIDs con IDs reales de auth.users
INSERT INTO public.usuarios (id, email, nombre_completo, rol, empresa_id) VALUES
  ('ceo-uuid-aqui', 'anngi@vplash.com', 'Anngi Ávila', 'ceo', 'empresa-uuid'),
  ('coo-uuid-aqui', 'mau@vplash.com', 'Mau Rojas', 'coo', 'empresa-uuid'),
  ('trafficer-uuid-aqui', 'trafficer@vplash.com', 'Trafficer', 'trafficer', 'empresa-uuid');

-- Insertar lanzamiento
INSERT INTO public.lanzamientos (
  empresa_id, nombre_lanzamiento, fase_anual, pilar_metodo, 
  fecha_apertura, ticket_precio, meta_unidades, presupuesto_ads_asignado, roas_meta, status
) VALUES (
  'empresa-uuid',
  'Vibes Builder Mayo 2026',
  1,
  'identidad',
  '2026-05-04',
  1497.00,
  120,
  14000.00,
  14.00,
  'lanzamiento'
) RETURNING id as lanzamiento_id;
*/

-- ============================================================================
-- CHECKLISTS DE VALIDACIÓN
-- ============================================================================

-- Ejecutar después de crear todas las tablas:
-- SELECT * FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT * FROM information_schema.table_constraints WHERE table_schema = 'public';

-- Verificar RLS está habilitado:
-- SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- Verificar índices creados:
-- SELECT * FROM pg_indexes WHERE schemaname = 'public';

-- ============================================================================
-- FIN DEL SCHEMA
-- ============================================================================
