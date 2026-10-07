-- ========================================================
-- SISTEMA DE GESTIÓN Y SEGUIMIENTO DE TRÁMITES DE TITULACIÓN
-- Esquema de Base de Datos PostgreSQL
-- ========================================================

-- Limpieza opcional (descomentar si se desea reiniciar el esquema)
-- DROP TABLE IF EXISTS documents CASCADE;
-- DROP TABLE IF EXISTS procedure_stages CASCADE;
-- DROP TABLE IF EXISTS procedures CASCADE;
-- DROP TABLE IF EXISTS projects_theses CASCADE;
-- DROP TABLE IF EXISTS advisors CASCADE;
-- DROP TABLE IF EXISTS students CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS roles CASCADE;

-- 1. Tabla de Roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL, -- Ej: 'ADMIN', 'STUDENT', 'ADVISOR', 'COORDINATOR', 'JURY'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Usuarios (Autenticación y Datos Generales)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    lastname VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER REFERENCES roles(id) ON DELETE RESTRICT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Estudiantes
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    student_code VARCHAR(50) UNIQUE NOT NULL, -- Matrícula / Código de estudiante
    faculty VARCHAR(150) NOT NULL,            -- Facultad / Escuela
    career VARCHAR(150) NOT NULL,             -- Carrera / Programa académico
    enrollment_year INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de Asesores / Tutores / Docentes
CREATE TABLE IF NOT EXISTS advisors (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    department VARCHAR(150) NOT NULL,         -- Departamento o área académica
    specialization VARCHAR(200),              -- Especialidad o línea de investigación
    max_students INTEGER DEFAULT 5            -- Límite de tesistas/estudiantes asignados
);

-- 5. Tabla de Períodos Académicos
CREATE TABLE IF NOT EXISTS academic_periods (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,               -- Ej: 2026-2
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_academic_period_dates
        CHECK (end_date >= start_date)
);

-- 6. Inscripción del estudiante al proceso de titulación
CREATE TABLE IF NOT EXISTS graduation_enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_period_id INTEGER NOT NULL REFERENCES academic_periods(id) ON DELETE RESTRICT,

    status VARCHAR(50) NOT NULL DEFAULT 'REGISTERED',
    -- REGISTERED, UNDER_REVIEW, ENABLED, REJECTED

    registration_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    observations TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_student_graduation_period
        UNIQUE (student_id, academic_period_id),

    CONSTRAINT chk_graduation_enrollment_status
        CHECK (status IN (
            'REGISTERED',
            'UNDER_REVIEW',
            'ENABLED',
            'REJECTED'
        ))
);

-- 5. Tabla de Proyectos de Tesis / Titulación
CREATE TABLE IF NOT EXISTS projects_theses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    abstract TEXT,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    advisor_id INTEGER REFERENCES advisors(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'PROPOSED',    -- PROPOSED, APPROVED, IN_PROGRESS, DEFENDED, REJECTED, COMPLETED
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approval_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Tabla de Trámites de Titulación
CREATE TABLE IF NOT EXISTS procedures (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    procedure_type VARCHAR(100) NOT NULL,     -- Ej: 'TESIS', 'EXAMEN_PROFESIONAL', 'DIPLOMADO', 'EXCELENCIA_ACADEMICA'
    current_stage VARCHAR(100) DEFAULT 'INICIO', -- Ej: 'REVISION_DOCUMENTOS', 'DESIGNACION_JURADO', 'DEFENSA', 'FINALIZADO'
    status VARCHAR(50) DEFAULT 'PENDING',     -- PENDING, IN_REVIEW, APPROVED, REJECTED, COMPLETED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Tabla de Historial / Seguimiento de Etapas del Trámite
CREATE TABLE IF NOT EXISTS procedure_stages (
    id SERIAL PRIMARY KEY,
    procedure_id INTEGER REFERENCES procedures(id) ON DELETE CASCADE,
    stage_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,              -- PENDING, APPROVED, REJECTED
    comments TEXT,
    updated_by INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Quién aprobó o revisó la etapa
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Tabla de Documentos Adjuntos
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    procedure_id INTEGER REFERENCES procedures(id) ON DELETE CASCADE,
    document_type VARCHAR(100) NOT NULL,      -- Ej: 'CARTA_LIBERACION', 'TESIS_PDF', 'CERTIFICADO_ESTUDIOS', 'COMPROBANTE_PAGO'
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_students_code ON students(student_code);
CREATE INDEX IF NOT EXISTS idx_procedures_student ON procedures(student_id);
CREATE INDEX IF NOT EXISTS idx_projects_student ON projects_theses(student_id);
CREATE INDEX IF NOT EXISTS idx_procedures_stages ON procedure_stages(procedure_id);

CREATE INDEX IF NOT EXISTS idx_graduation_enrollments_student
ON graduation_enrollments(student_id);

CREATE INDEX IF NOT EXISTS idx_graduation_enrollments_period
ON graduation_enrollments(academic_period_id);

CREATE INDEX IF NOT EXISTS idx_graduation_enrollments_status
ON graduation_enrollments(status);