using System.Text.RegularExpressions;
using Ance.Application.Abstracciones;
using Ance.Application.Dtos;
using Ance.Application.Excepciones;

namespace Ance.Application;

public class SolicitudService
{
    private readonly ISolicitudRepository _repositorio;

    public SolicitudService(ISolicitudRepository repositorio)
    {
        _repositorio = repositorio;
    }

    public Task<List<SolicitudResumenDto>> ListarAsync(int? estadoId) =>
        _repositorio.ListarAsync(estadoId);

    public Task<CatalogosDto> ObtenerCatalogosAsync() =>
        _repositorio.ObtenerCatalogosAsync();

    public async Task<SolicitudDetalleDto> ObtenerPorIdAsync(int id)
    {
        var solicitud = await _repositorio.ObtenerPorIdAsync(id);
        if (solicitud is null)
            throw new NegocioException(404, "NO_ENCONTRADO", $"No existe la solicitud con id {id}.");
        return solicitud;
    }

    public async Task<List<HistorialDto>> ListarHistorialAsync(int id)
    {
        await ObtenerPorIdAsync(id);
        return await _repositorio.ListarHistorialAsync(id);
    }

    public Task<SolicitudDetalleDto> CrearAsync(CrearSolicitudRequest datos)
    {
        Requerido(datos.Solicitante, "El solicitante es obligatorio.");
        Requerido(datos.Correo, "El correo es obligatorio.");
        Requerido(datos.Titulo, "El título es obligatorio.");
        Requerido(datos.Descripcion, "La descripción es obligatoria.");

        if (datos.TipoSolicitudId is null)
            Error("El tipo de solicitud es obligatorio.");

        if (!Regex.IsMatch(datos.Correo!.Trim(), @"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$"))
            Error("El correo no tiene un formato válido.");

        if (datos.Titulo?.Length > 150)
            Error("El titulo es muy largo, resumelo");

        if (datos.PrioridadId < 1 || datos.PrioridadId > 4)
            Error("La prioridad debe ser correcta");
        return _repositorio.CrearAsync(datos);
    }

    public async Task AsignarResponsableAsync(int id, AsignarResponsableRequest datos)
    {
        if (datos.ResponsableId is null)
            Error("Debe tener responsable");
        await _repositorio.AsignarResponsableAsync(id, datos.ResponsableId!.Value);
    }

    public async Task CambiarEstadoAsync(int id, CambiarEstadoRequest datos)
    {
        if (datos.EstadoId is null)
            Error("Elige un estado correcto");
        await _repositorio.CambiarEstadoAsync(id, datos.EstadoId!.Value, datos.Comentario);
    }

    private static void Requerido(string? valor, string mensaje)
    {
        if (string.IsNullOrWhiteSpace(valor))
            Error(mensaje);
    }

    private static void Error(string mensaje) =>
        throw new NegocioException(400, "VALIDACION", mensaje);
}