import ansible_runner

result = ansible_runner.run(
    private_data_dir='/home/jhon/Projects/ansible_runner_python/config',
    playbook='whoami.yml'
)

print("Estado de la ejecución:", result.status)
print("Código de retorno:", result.rc)
print("Estadísticas:", result.stats)
