using System.Data;
using Ance.Application.Abstracciones;
using Ance.Application.Dtos;
using Ance.Application.Excepciones;
using Microsoft.Data.SqlClient;

namespace Ance.Infrastructure;

public class SolicitudRepository : ISolicitudRepository
{
    private readonly string _cadenaConexion;

    public SolicitudRepository(string cadenaConexion)
    {
        _cadenaConexion = cadenaConexion;
    }

    private async Task<T> EjecutarAsync<T>(string procedimiento,
                                           Action<SqlParameterCollection> parametros,
                                           Func<SqlDataReader, Task<T>> leer)
    {
        try
        {
            await using var conexion = new SqlConnection(_cadenaConexion);
            await conexion.OpenAsync();

            await using var comando = new SqlCommand(procedimiento, conexion)
            {
                CommandType = CommandType.StoredProcedure
            };
            parametros(comando.Parameters);

            await using var reader = await comando.ExecuteReaderAsync();
            return await leer(reader);
        }
        catch (SqlException ex) when (ex.Number >= 50400 && ex.Number <= 50499)
        {
            var codigo = ex.Number switch
            {
                50400 => "VALIDACION",
                50404 => "NO_ENCONTRADO",
                50409 => "CONFLICTO",
                _ => "REGLA_NEGOCIO"
            };
            throw new NegocioException(ex.Number - 50000, codigo, ex.Message);
        }
    }

    private static void Param(SqlParameterCollection p, string nombre, object? valor) =>
        p.AddWithValue(nombre, valor ?? DBNull.Value);

    private static int Entero(SqlDataReader r, string c) => Convert.ToInt32(r[c]);
    private static int? EnteroNulo(SqlDataReader r, string c) => r[c] is DBNull ? null : Convert.ToInt32(r[c]);
    private static string Texto(SqlDataReader r, string c) => Convert.ToString(r[c]) ?? "";
    private static string? TextoNulo(SqlDataReader r, string c) => r[c] is DBNull ? null : Convert.ToString(r[c]);
    private static DateTime Fecha(SqlDataReader r, string c) => DateTime.SpecifyKind((DateTime)r[c], DateTimeKind.Utc);
    private static DateTime? FechaNula(SqlDataReader r, string c) => r[c] is DBNull ? null : Fecha(r, c);


    public Task<List<SolicitudResumenDto>> ListarAsync(int? estadoId) =>
        EjecutarAsync("dbo.sp_Solicitud_Listar",
            p => Param(p, "@EstadoId", estadoId),
            async r =>
            {
                var lista = new List<SolicitudResumenDto>();
                while (await r.ReadAsync())
                {
                    lista.Add(new SolicitudResumenDto
                    {
                        Id = Entero(r, "SolicitudId"),
                        Folio = Texto(r, "Folio"),
                        Titulo = Texto(r, "Titulo"),
                        Solicitante = Texto(r, "Solicitante"),
                        PrioridadId = Entero(r, "PrioridadId"),
                        Prioridad = Texto(r, "NombrePrioridad"),
                        ResponsableId = EnteroNulo(r, "ResponsableId"),
                        Responsable = TextoNulo(r, "NombreResponsable"),
                        EstadoId = Entero(r, "EstadoId"),
                        Estado = Texto(r, "NombreSolicitudEstado"),
                        FechaCreacion = Fecha(r, "FechaCreacion")
                    });
                }
                return lista;
            });

    public Task<SolicitudDetalleDto> CrearAsync(CrearSolicitudRequest d) =>
        EjecutarAsync("dbo.sp_Solicitud_Crear",
            p =>
            {
                Param(p, "@Solicitante", d.Solicitante);
                Param(p, "@Correo", d.Correo);
                Param(p, "@TipoSolicitudId", d.TipoSolicitudId);
                Param(p, "@Titulo", d.Titulo);
                Param(p, "@Descripcion", d.Descripcion);
                Param(p, "@PrioridadId", d.PrioridadId ?? 2);
                Param(p, "@ResponsableId", d.ResponsableId);
            },
            async r =>
            {
                await r.ReadAsync();
                return MapearDetalle(r);
            });

    public Task AsignarResponsableAsync(int id, int responsableId) =>
        EjecutarAsync("dbo.sp_Solicitud_AsignarResponsable",
            p =>
            {
                Param(p, "@SolicitudId", id);
                Param(p, "@ResponsableId", responsableId);
            },
            _ => Task.FromResult(true));

    public Task CambiarEstadoAsync(int id, int estadoId, string? comentario) =>
        EjecutarAsync("dbo.sp_Solicitud_CambiarEstado",
            p =>
            {
                Param(p, "@SolicitudId", id);
                Param(p, "@EstadoNuevoId", estadoId);
                Param(p, "@Comentario", comentario);
            },
            _ => Task.FromResult(true));

    public Task<CatalogosDto> ObtenerCatalogosAsync() =>
        EjecutarAsync("dbo.sp_Catalogos_Listar",
            _ => { },
            async r =>
            {
                var c = new CatalogosDto();
                c.Estados = await LeerCatalogo(r);
                await r.NextResultAsync();
                c.Prioridades = await LeerCatalogo(r);
                await r.NextResultAsync();
                c.Tipos = await LeerCatalogo(r);
                await r.NextResultAsync();
                c.Responsables = await LeerCatalogo(r);
                await r.NextResultAsync();
                while (await r.ReadAsync())
                    c.Transiciones.Add(new[] { Entero(r, "EstadoOrigenId"), Entero(r, "EstadoDestinoId") });
                return c;
            });

    private static async Task<List<ElementoCatalogoDto>> LeerCatalogo(SqlDataReader r)
    {
        var lista = new List<ElementoCatalogoDto>();
        while (await r.ReadAsync())
            lista.Add(new ElementoCatalogoDto { Id = Entero(r, "Id"), Nombre = Texto(r, "Nombre") });
        return lista;
    }

    public Task<SolicitudDetalleDto?> ObtenerPorIdAsync(int id) =>
            EjecutarAsync("dbo.sp_Solicitud_ObtenerPorId",
                p => Param(p, "@SolicitudId", id),
                async r => await r.ReadAsync() ? MapearDetalle(r) : null);

    private static SolicitudDetalleDto MapearDetalle(SqlDataReader r) => new SolicitudDetalleDto
    {
        Id = Entero(r, "SolicitudId"),
        Folio = Texto(r, "Folio"),
        Titulo = Texto(r, "Titulo"),
        Solicitante = Texto(r, "Solicitante"),
        Correo = Texto(r, "Correo"),
        TipoSolicitudId = Entero(r, "TipoSolicitudId"),
        TipoSolicitud = Texto(r, "TipoSolicitud"),
        Descripcion = Texto(r, "Descripcion"),
        PrioridadId = Entero(r, "PrioridadId"),
        Prioridad = Texto(r, "NombrePrioridad"),
        ResponsableId = EnteroNulo(r, "ResponsableId"),
        Responsable = TextoNulo(r, "NombreResponsable"),
        EstadoId = Entero(r, "EstadoId"),
        Estado = Texto(r, "NombreSolicitudEstado"),
        ComentarioResolucion = TextoNulo(r, "ComentarioResolucion"),
        FechaCreacion = Fecha(r, "FechaCreacion"),
        FechaActualizacion = FechaNula(r, "FechaActualizacion")
    };
    
    public Task<List<HistorialDto>> ListarHistorialAsync(int id) =>
        EjecutarAsync("dbo.sp_HistorialSolicitud_Listar",
            p => Param(p, "@SolicitudId", id),
            async r =>
            {
                var lista = new List<HistorialDto>();
                while (await r.ReadAsync())
                {
                    lista.Add(new HistorialDto
                    {
                        Id = Convert.ToInt64(r["HistorialId"]),
                        Fecha = Fecha(r, "Fecha"),
                        TipoAccionId = Entero(r, "TipoAccionId"),
                        Accion = Texto(r, "Accion"),
                        EstadoAnterior = TextoNulo(r, "EstadoAnterior"),
                        EstadoNuevo = TextoNulo(r, "EstadoNuevo"),
                        ResponsableAnterior = TextoNulo(r, "ResponsableAnterior"),
                        ResponsableNuevo = TextoNulo(r, "ResponsableNuevo"),
                        Detalle = Texto(r, "Detalle")
                    });
                }
                return lista;
            });
}