module my_addr::Company {
    use std::vector;

    struct Employees has key, drop {
        people: vector<Employee>
    }

    struct Employee has store, drop, copy {
        name: vector<u8>,
        age: u8,
        income: u64
    }

    public fun create_employee(_employee: Employee, _employees: &mut Employees): Employee {
        let newEmployee = Employee {
            name: _employee.name,
            age: _employee.age,
            income: _employee.income,
        };

        add_employee(_employees, newEmployee);
        newEmployee
    }

    public fun add_employee(_employees: &mut Employees, _employee: Employee) {
        vector::push_back(&mut _employees.people, _employee);
    }

    public fun increase_income(employee: &mut Employee, bonus: u64): &mut Employee {
        employee.income = employee.income + bonus;
        employee
    }

    public fun decrease_income(employee: &mut Employee, penalty: u64): &mut Employee {
        employee.income = employee.income - penalty;
        employee
    }

    public fun multiple_income(employee: &mut Employee, factor: u64): &mut Employee {
        employee.income = employee.income * factor;
        employee
    }

    public fun divide_income(employee: &mut Employee, dividor: u64): &mut Employee {
        employee.income = employee.income / dividor;
        employee
    }

    public fun is_employee_age_even(employee: &mut Employee): bool {
        let isEven: bool;
        if(employee.age %2 == 0){
            isEven = true
        } else {
            isEven = false
        };
        isEven
    }

    #[test]
    public fun testing(){
        let ajay = Employee {
            name: b"Ajay",
            age: 24,
            income: 70_000
        };
        let employees = Employees {
            people: (vector[ajay])
        };
        let newEmployee = create_employee(ajay, &mut employees);
        assert!(newEmployee.name == b"Ajay", 0);
        let newEmployee = increase_income(&mut newEmployee, 10);
        assert!(newEmployee.income == 70_010, 1);
        let newEmployee = decrease_income(newEmployee, 5);
        assert!(newEmployee.income == 70_005, 2);
        let newEmployee = multiple_income(newEmployee, 2);
        assert!(newEmployee.income == 140_010, 3);
        let newEmployee = divide_income(newEmployee, 2);
        assert!(newEmployee.income == 70_005, 4);
        assert!(is_employee_age_even(newEmployee) == true, 5);
    }

}