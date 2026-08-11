from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('cargas', '0005_carga_empresa_avaliada'),
    ]

    operations = [
        migrations.AddField(
            model_name='carga',
            name='tipo_carreta',
            field=models.CharField(
                choices=[
                    ('sider', 'Sider'),
                    ('bau', 'Baú'),
                    ('carga_seca', 'Carga seca'),
                    ('graneleiro', 'Graneleiro'),
                    ('tanque', 'Tanque'),
                    ('camara_fria', 'Câmara fria'),
                    ('cacamba', 'Caçamba'),
                    ('prancha', 'Prancha'),
                    ('porta_container', 'Porta-contêiner'),
                    ('outro', 'Outro'),
                ],
                default='carga_seca',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='carga',
            name='empresa_destino',
            field=models.CharField(
                blank=True,
                help_text='Empresa onde a carga será descarregada',
                max_length=255,
            ),
        ),
        migrations.AddField(
            model_name='carga',
            name='local_carreta',
            field=models.CharField(
                blank=True,
                help_text='Onde a carreta está para o motorista acoplar',
                max_length=255,
            ),
        ),
        migrations.AlterField(
            model_name='carga',
            name='status',
            field=models.CharField(
                choices=[
                    ('disponivel', 'Disponível'),
                    ('aguardando_aceite', 'Aguardando aceite do motorista'),
                    ('acoplar_carreta', 'Acoplar carreta'),
                    ('em_transito', 'Em Trânsito'),
                    ('finalizado', 'Concluída'),
                ],
                default='disponivel',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='candidatura',
            name='status',
            field=models.CharField(
                choices=[
                    ('pendente', 'Pendente'),
                    ('aceita', 'Aceita'),
                    ('recusada', 'Recusada'),
                    ('cancelada', 'Cancelada pelo motorista'),
                ],
                default='pendente',
                max_length=10,
            ),
        ),
    ]
