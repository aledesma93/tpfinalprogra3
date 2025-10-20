// ========= Enums y Value Objects =========
public enum UserRole { Administrador, Telefonista, Supervisor }

public enum IncidentState
{
    Abierto,        // nace aquí
    Asignado,       // al reasignar
    EnAnalisis,     // al modificar con cambios sustanciales
    Resuelto,       // botón Resolver (requiere dato final)
    Cerrado,        // botón Cerrar Incidencia (requiere comentario)
    Reabierto       // si se reabre
}

public sealed class Email
{
    public string Value { get; private set; }
    private Email() { }
    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || !value.Contains("@"))
            throw new ArgumentException("Email inválido.");
        Value = value.Trim();
    }
}

// ========= Entidades base =========
public abstract class Entity
{
    public Guid Id { get; protected set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; protected set; } = DateTime.UtcNow;
    public Guid CreatedByUserId { get; protected set; }
    public DateTime? UpdatedAt { get; protected set; }
    public Guid? UpdatedByUserId { get; protected set; }
    public bool IsDeleted { get; protected set; } = false; // nunca borrar físicamente
}

// ========= Usuarios y Clientes =========
public class User : Entity
{
    public string Username { get; private set; } = default!;
    public string FullName { get; private set; } = default!;
    public UserRole Role { get; private set; }

    // Navegación
    public ICollection<Incident> IncidentsAssigned { get; private set; } = new List<Incident>();

    private User() { }
    public User(string username, string fullName, UserRole role, Guid creatorId)
    {
        Username = username;
        FullName = fullName;
        Role = role;
        CreatedByUserId = creatorId;
    }
}

public class Customer : Entity
{
    public string DocumentNumber { get; private set; } = default!;
    public string Name { get; private set; } = default!;
    public Email Email { get; private set; } = default!;
    public string? Phone { get; private set; }

    // Navegación
    public ICollection<Incident> Incidents { get; private set; } = new List<Incident>();

    private Customer() { }
    public Customer(string documentNumber, string name, Email email, string? phone, Guid creatorId)
    {
        DocumentNumber = documentNumber;
        Name = name;
        Email = email;
        Phone = phone;
        CreatedByUserId = creatorId;
    }
}

// ========= Catálogos administrables =========
public class IncidentType : Entity
{
    public string Name { get; private set; } = default!;
    public string? Description { get; private set; }
    private IncidentType() { }
    public IncidentType(string name, string? description, Guid creatorId)
    {
        Name = name; Description = description; CreatedByUserId = creatorId;
    }
}

public class Priority : Entity
{
    public string Name { get; private set; } = default!;   
    public int Weight { get; private set; }               
    private Priority() { }
    public Priority(string name, int weight, Guid creatorId)
    {
        Name = name; Weight = weight; CreatedByUserId = creatorId;
    }
}

// ========= Incidencias y objeto de historial/comentarios =========
public class Incident : Entity
{
    public string Number { get; private set; } = default!; 
    public Guid CustomerId { get; private set; }
    public Customer Customer { get; private set; } = default!;

    public Guid TypeId { get; private set; }
    public IncidentType Type { get; private set; } = default!;

    public Guid PriorityId { get; private set; }
    public Priority Priority { get; private set; } = default!;

    public string Problem { get; private set; } = default!;
    public IncidentState State { get; private set; } = IncidentState.Abierto;

    public Guid OwnerUserId { get; private set; }          // creador 
    public Guid AssignedToUserId { get; private set; }     // asignado actual
    public User AssignedToUser { get; private set; } = default!;

    public string? ResolutionNote { get; private set; }
    public string? CloseComment { get; private set; }

    public ICollection<IncidentComment> Comments { get; private set; } = new List<IncidentComment>();
    public ICollection<IncidentAssignment> Assignments { get; private set; } = new List<IncidentAssignment>();
    public ICollection<IncidentStateHistory> StateHistory { get; private set; } = new List<IncidentStateHistory>();

    private Incident() { }

    public static Incident Create(
        string number,
        Customer customer,
        IncidentType type,
        Priority priority,
        string problem,
        User creator)
    {
        var inc = new Incident
        {
            Number = number,
            Customer = customer, CustomerId = customer.Id,
            Type = type, TypeId = type.Id,
            Priority = priority, PriorityId = priority.Id,
            Problem = problem.Trim(),
            OwnerUserId = creator.Id,
            AssignedToUser = creator, AssignedToUserId = creator.Id,
            CreatedByUserId = creator.Id
        };
        inc.AddStateHistory(IncidentState.Abierto, creator.Id, "Incidente creado.");
        inc.AddAssignment(creator.Id, creator.Id, "Asignación inicial al creador.");
        return inc;
    }

    public void Reassign(User supervisor, User newAssignee, string reason)
    {
        EnsureSupervisor(supervisor);
        if (AssignedToUserId == newAssignee.Id) return;
        AssignedToUser = newAssignee; AssignedToUserId = newAssignee.Id;
        UpdatedByUserId = supervisor.Id; UpdatedAt = DateTime.UtcNow;
        AddAssignment(supervisor.Id, newAssignee.Id, reason);
        TransitionTo(IncidentState.Asignado, supervisor.Id, "Reasignado por supervisor.");
    }

    public void Modify(User actor, Action<Incident> changes, string? note = null)
    {
        changes(this);
        UpdatedByUserId = actor.Id; UpdatedAt = DateTime.UtcNow;
        TransitionTo(IncidentState.EnAnalisis, actor.Id, note ?? "Modificación realizada.");
    }

    public void Resolve(User actor, string resolutionNote)
    {
        if (string.IsNullOrWhiteSpace(resolutionNote)) throw new ArgumentException("Se requiere nota de resolución.");
        ResolutionNote = resolutionNote.Trim();
        UpdatedByUserId = actor.Id; UpdatedAt = DateTime.UtcNow;
        TransitionTo(IncidentState.Resuelto, actor.Id, "Incidente resuelto.");
    }

    public void Close(User actor, string closeComment)
    {
        if (string.IsNullOrWhiteSpace(closeComment)) throw new ArgumentException("Se requiere comentario de cierre.");
        CloseComment = closeComment.Trim();
        UpdatedByUserId = actor.Id; UpdatedAt = DateTime.UtcNow;
        TransitionTo(IncidentState.Cerrado, actor.Id, "Incidente cerrado.");
    }

    public void Reopen(User actor, string reason)
    {
        Comments.Add(new IncidentComment(this.Id, actor.Id, $"Reapertura: {reason}"));
        UpdatedByUserId = actor.Id; UpdatedAt = DateTime.UtcNow;
        TransitionTo(IncidentState.Reabierto, actor.Id, "Reabierto por seguimiento.");
    }

    private void TransitionTo(IncidentState newState, Guid actorId, string? note)
    {
        // Reglas: no permitir cambios manuales arbitrarios, solo por métodos de dominio.
        // Secuencias válidas controladas por los métodos públicos.
        State = newState;
        AddStateHistory(newState, actorId, note);
    }

    private void AddAssignment(Guid actorId, Guid assigneeId, string? note)
    {
        Assignments.Add(new IncidentAssignment(this.Id, actorId, assigneeId, note));
    }

    private void AddStateHistory(IncidentState state, Guid actorId, string? note)
    {
        StateHistory.Add(new IncidentStateHistory(this.Id, state, actorId, note));
    }

    private static void EnsureSupervisor(User user)
    {
        if (user.Role != UserRole.Supervisor && user.Role != UserRole.Administrador)
            throw new InvalidOperationException("Solo Supervisor o Administrador pueden reasignar.");
    }
}

public class IncidentComment : Entity
{
    public Guid IncidentId { get; private set; }
    public Guid AuthorUserId { get; private set; }
    public string Text { get; private set; } = default!;
    private IncidentComment() { }
    public IncidentComment(Guid incidentId, Guid authorUserId, string text)
    {
        IncidentId = incidentId; AuthorUserId = authorUserId; Text = text.Trim();
        CreatedByUserId = authorUserId;
    }
}

public class IncidentAssignment : Entity
{
    public Guid IncidentId { get; private set; }
    public Guid AssignedByUserId { get; private set; }
    public Guid AssignedToUserId { get; private set; }
    public string? Note { get; private set; }
    private IncidentAssignment() { }
    public IncidentAssignment(Guid incidentId, Guid byUserId, Guid toUserId, string? note)
    {
        IncidentId = incidentId; AssignedByUserId = byUserId; AssignedToUserId = toUserId; Note = note;
        CreatedByUserId = byUserId;
    }
}

public class IncidentStateHistory : Entity
{
    public Guid IncidentId { get; private set; }
    public IncidentState State { get; private set; }
    public Guid ActorUserId { get; private set; }
    public string? Note { get; private set; }
    private IncidentStateHistory() { }
    public IncidentStateHistory(Guid incidentId, IncidentState state, Guid actorUserId, string? note)
    {
        IncidentId = incidentId; State = state; ActorUserId = actorUserId; Note = note;
        CreatedByUserId = actorUserId;
    }
}

// ========= Eventos de dominio para notificaciones por email =========
public interface IDomainEvent { DateTime OccurredOn { get; } }

public class IncidentCreatedEvent : IDomainEvent
{
    public Guid IncidentId { get; }
    public string IncidentNumber { get; }
    public Email CustomerEmail { get; }
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public IncidentCreatedEvent(Guid incidentId, string number, Email email)
    { IncidentId = incidentId; IncidentNumber = number; CustomerEmail = email; }
}

public class IncidentResolvedEvent : IDomainEvent
{
    public Guid IncidentId { get; }
    public Email CustomerEmail { get; }
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public IncidentResolvedEvent(Guid incidentId, Email email)
    { IncidentId = incidentId; CustomerEmail = email; }
}

public class IncidentClosedEvent : IDomainEvent
{
    public Guid IncidentId { get; }
    public Email CustomerEmail { get; }
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public IncidentClosedEvent(Guid incidentId, Email email)
    { IncidentId = incidentId; CustomerEmail = email; }
}
