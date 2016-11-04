create table department (
    dept_id integer not null,
    dept_name varchar(30) not null,
    dept_location varchar(30) not null,
    unique(dept_id)
);

create table employee (
    emp_id integer not null,
    emp_name varchar(50) not null,
    dept_id integer not null,
    salary integer not null,
    unique(emp_id)
);

insert department values (10, 'Accounts', 'Delhi');
insert department values (20, 'Marketing', 'Delhi');
insert department values (30, 'IT', 'Warsaw');
insert department values (40, 'Production', 'Hyderabad');
insert department values (50, 'Sales', 'Bengaluru');

insert employee values(1, 'Jojo', 20, 5000);
insert employee values(2, 'Popat Lal', 30, 15000);
insert employee values(3, 'Santa Singh', 40, 25000);
insert employee values(4, 'Banta Singh', 20, 7500);
insert employee values(5, 'Sohan Lal', 20, 15000);
insert employee values(6, 'Kk', 10, 12000);
insert employee values(7, 'Bob', 20, 35000);
insert employee values(8, 'John',  30, 25000);
insert employee values(9, 'Smith', 40, 5000);



SELECT dep.dept_id, COUNT(emp.emp_id) [COUNT], SUM(salary) [sum_of_salary]
FROM department	dep
JOIN employee	emp ON (emp.dept_id = dep.dept_id)
GROUP BY dep.dept_id;