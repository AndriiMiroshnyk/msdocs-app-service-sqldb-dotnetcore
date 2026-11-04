
using DotNetCoreSqlDb.Controllers;
using DotNetCoreSqlDb.Data;
using DotNetCoreSqlDb.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace DotNetCoreSqlDb.Tests;

public class TodosControllerTests
{
    private static async Task<MyDatabaseContext> CreateContextAsync(
        SqliteConnection connection)
    {
        var options = new DbContextOptionsBuilder<MyDatabaseContext>()
            .UseSqlite(connection)
            .Options;

        var context = new MyDatabaseContext(options);

        try
        {
            await context.Database.EnsureCreatedAsync(TestContext.Current.CancellationToken);
            return context;
        }
        catch
        {
            await context.DisposeAsync();
            throw;
        }
    }

    private static TodosController CreateController(
        MyDatabaseContext context)
    {
        return new TodosController(
            context,
            NullLogger<TodosController>.Instance);
    }

    [Fact]
    public async Task Index_ReturnsTodos()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync(TestContext.Current.CancellationToken);

        await using var context = await CreateContextAsync(connection);

        context.Todo.Add(new Todo
        {
            Description = "Test task"
        });

        await context.SaveChangesAsync(TestContext.Current.CancellationToken);

        var controller = CreateController(context);
        var result = await controller.Index();

        var view = Assert.IsType<ViewResult>(result);
        var model = Assert.IsType<TodosIndexViewModel>(view.Model);

        var todo = Assert.Single(model.Todos);
        Assert.Equal("Test task", todo.Description);
    }

    [Fact]
    public async Task Create_AddsTodoToDatabase()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync(TestContext.Current.CancellationToken);

        await using var context = await CreateContextAsync(connection);

        var controller = CreateController(context);

        var todo = new Todo
        {
            Description = "New task"
        };

        var result = await controller.Create(todo);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal("Index", redirect.ActionName);

        var savedTodo = await context.Todo.SingleAsync(TestContext.Current.CancellationToken);
        Assert.Equal("New task", savedTodo.Description);
    }

    [Fact]
    public async Task Delete_RemovesTodoFromDatabase()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync(TestContext.Current.CancellationToken);

        await using var context = await CreateContextAsync(connection);

        var todo = new Todo
        {
            Description = "Task to delete"
        };

        context.Todo.Add(todo);
        await context.SaveChangesAsync(TestContext.Current.CancellationToken);

        var controller = CreateController(context);

        var result = await controller.Delete(todo.ID);

        var redirect = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal("Index", redirect.ActionName);

        Assert.Empty(await context.Todo.ToListAsync(TestContext.Current.CancellationToken));
    }

    [Fact]
    public async Task Delete_NonExistingTodo_ReturnsNotFound()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync(TestContext.Current.CancellationToken);

        await using var context = await CreateContextAsync(connection);

        var controller = CreateController(context);

        var result = await controller.Delete(999);

        Assert.IsType<NotFoundResult>(result);
    }
}
