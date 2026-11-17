# Solicitudes de Servicio · Digitalización

Aplicación web para registrar y gestionar las solicitudes de servicio del área de Digitalización.

- Base de datos: SQL Server
- Backend: C# · ASP.NET Core 8 · API REST · ADO.NET
- Frontend: HTML, CSS y JavaScript puro, servido por la misma API

## Estructura

ANCE/
- DDBB/AnceDB.sql
- Backend/
    - Ance.sln
    - src/
        - Ance.Api/
        - Ance.Application/
        - Ance.Infrastructure/


## Requisitos

- .NET SDK 8
- SQL Server 2019+ (Express funciona)
- sqlcmd o SQL Server Management Studio

## Instalación y ejecución

1. Base de datos. El script crea la base ANCEPRACTICA y debe ejecutarse sobre una base nueva:
   powershell
   sqlcmd -S .\SQLEXPRESS -E -Q "DROP DATABASE IF EXISTS ANCEPRACTICA"
   sqlcmd -S .\SQLEXPRESS -E -f 65001 -b -i DDBB\AnceDB.sql
   
   -f 65001 es necesario para que los acentos se guarden correctamente.

2. Cadena de conexión. Ajustar Backend/src/Ance.Api/appsettings.json si el servidor no es .\SQLEXPRESS:
   json
   "AnceDb": "Server=.\\SQLEXPRESS;Database=ANCEPRACTICA;Trusted_Connection=True;TrustServerCertificate=True;"
   

3. Compilar y ejecutar:
   powershell
   cd Backend
   dotnet build
   dotnet run --project src\Ance.Api
   

4. Abrir http://localhost:<puerto>/ para la aplicación y http://localhost:<puerto>/swagger para probar la API.

## Despliegue

powershell
cd Backend
dotnet publish src\Ance.Api -c Release -o ..\publish


La carpeta publish incluye la API y el frontend (wwwroot). Se ejecuta con dotnet Ance.Api.dll o se publica en IIS con el ASP.NET Core Hosting Bundle 8. En producción, la cadena de conexión se configura con la variable de entorno ConnectionStrings__AnceDb.

## API REST

| Método | Ruta | Descripción | Respuestas |
|---|---|---|---|
| GET | /api/solicitudes?estadoId= | Listar (filtro opcional por estado) | 200 |
| GET | /api/solicitudes/{id} | Consultar por id | 200, 404 |
| POST | /api/solicitudes | Crear | 201, 400, 422 |
| PUT | /api/solicitudes/{id}/responsable | Asignar responsable | 204, 400, 404, 409, 422 |
| PATCH | /api/solicitudes/{id}/estado | Cambiar estado | 204, 400, 404, 409, 422 |
| GET | /api/solicitudes/{id}/historial | Historial cronológico | 200, 404 |
| GET | /api/catalogos | Estados, prioridades, tipos, responsables y transiciones | 200 |

Todos los errores responden con el formato { "code": "", "message": "" }. Los errores no controlados responden 500 sin exponer detalles internos y se registran en el log.

## Decisiones de arquitectura

1. Separación en capas: Api solo recibe HTTP, Application valida y define las operaciones que necesita mediante la interfaz ISolicitudRepository; Infrastructure la implementa con SQL Server. La lógica no depende de la base de datos
2. Procedimientos almacenados como único acceso a datos, ejecutados con ADO.NET para controlar parámetros y resultados
3. Validación en tres niveles:
   - Interfaz: valida el formulario y solo muestra las transiciones permitidas; "En proceso" se deshabilita sin responsable y "Resuelta" exige comentario
   - API: valida obligatorios, formato de correo y longitud del título
   - Base de datos: las reglas de negocio viven en los procedimientos, y las restricciones CHECK y las llaves foráneas impiden datos inválidos aunque se escriba directo en las tablas
4. Transiciones como datos. La tabla TransicionEstado define los cambios permitidos; agregar o quitar una transición no requiere cambiar código
5. Errores de negocio con código propio. Los procedimientos lanzan THROW 504xx (50000 + código HTTP). El repositorio los convierte en NegocioException y el manejador global de excepciones responde con el código HTTP correspondiente
6. Historial dentro de la misma transacción que cada cambio, para que ninguna acción quede sin registrar. Las lecturas previas a un cambio usan UPDLOCK, HOLDLOCK para evitar conflictos entre usuarios simultáneos
7. Folio automático con una SEQUENCE (SOL-AAAA-000001). Las fechas se guardan en UTC y el frontend las muestra en hora local
8. Frontend servido por la API desde wwwroot: un solo despliegue, misma dirección para la página y la API (sin necesidad de CORS)

## Supuestos

- El enunciado no define los tipos de solicitud; se creó el catálogo TipoSolicitud con Incidencia, Acceso, Requerimiento y Consulta, ampliable sin cambiar código.
- La prioridad predeterminada al crear es Media.
- Las solicitudes en estado final (Cerrada o Cancelada) no se pueden reasignar.

## Bonus implementados

- Backend: manejo global de excepciones (IExceptionHandler) y Swagger.