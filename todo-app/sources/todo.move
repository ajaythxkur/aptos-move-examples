module my_addr::Todo {
    use std::signer;
    use aptos_framework::event;
    use std::table::{Self, Table};
    use aptos_framework::account;
    use std::string::String;

    struct TodoList has key {
        tasks: Table<u64, Task>,
        set_task_event: event::EventHandle<Task>,
        counter: u64
    }

    struct Task has copy, store, drop {
        id: u64,
        address: address,
        content: String,
        completed: bool
    }

    // TODO LIST IS NOT INITIALIZED
    const ENOT_INITIALIZED: u64 = 0;
    // TASK DOESNT EXIST
    const ETASK_DOESNT_EXIST: u64 = 1;
    // TASK ALREADY COMPLETED
    const ETASK_ALREADY_COMPLETED: u64 = 2;

    public entry fun create_list(account: &signer) {
        let account_address = signer::address_of(account);
        if(!exists<TodoList>(account_address)){
            move_to(account, TodoList {
                tasks: table::new(),
                set_task_event: account::new_event_handle<Task>(account),
                counter: 0
            });
        }
    }

    public entry fun create_task(account: &signer, content: String) acquires TodoList {
        let addr = signer::address_of(account);
        assert!(exists<TodoList>(addr), ENOT_INITIALIZED);
        let todolist = borrow_global_mut<TodoList>(addr);
        let counter = todolist.counter + 1;
        let task = Task {
            id: counter,
            address: addr,
            content,
            completed: false
        };
        table::upsert(&mut todolist.tasks, counter, task);
        todolist.counter = counter;
        event::emit_event<Task>(
            &mut todolist.set_task_event,
            task
        );
    }

    public entry fun complete_task(account: &signer, task_id: u64) acquires TodoList {
        let addr = signer::address_of(account);
        assert!(exists<TodoList>(addr), ENOT_INITIALIZED);
        let todolist = borrow_global_mut<TodoList>(addr);
        assert!(table::contains(&todolist.tasks, task_id), ETASK_DOESNT_EXIST);
        let task = table::borrow_mut(&mut todolist.tasks, task_id);
        assert!(task.completed == false, ETASK_ALREADY_COMPLETED);
        task.completed = true;
    }
}