from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Cadastro
    path('api/cadastro_usuario/', include('cadastro_usuario.urls')),
    
    # Perfis
    path('api/usuario/', include('usuario.urls')),
    
    # Cargas
    path('api/fretes/', include('cargas.urls')),
    
    # Avaliações
    path('api/avaliacao/', include('avaliacao.urls')),

    # JWT — login e refresh de token
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]