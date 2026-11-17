namespace Ance.Application.Excepciones;

public class NegocioException : Exception
{
    public NegocioException(int statusCode, string codigo, string mensaje) : base(mensaje)
    {
        StatusCode = statusCode;
        Codigo = codigo;
    }

    public int StatusCode { get; }
    public string Codigo { get; }
}