namespace Ance.Application.Dtos;

public class CrearSolicitudRequest
{
    public string? Solicitante { get; set; }
    public string? Correo { get; set; }
    public int? TipoSolicitudId { get; set; }
    public string? Titulo { get; set; }
    public string? Descripcion { get; set; }
    public int? PrioridadId { get; set; }
    public int? ResponsableId { get; set; }
}

public class AsignarResponsableRequest
{
    public int? ResponsableId { get; set; }
}

public class CambiarEstadoRequest
{
    public int? EstadoId { get; set; }
    public string? Comentario { get; set; }
}