# fretesil/urls.py
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .serializers import CustomTokenSerializer

class CustomTokenView(TokenObtainPairView):
    serializer_class = CustomTokenSerializer

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/cadastro_usuario/', include('cadastro_usuario.urls')),
    path('api/usuario/', include('usuario.urls')),
    path('api/fretes/', include('cargas.urls')),
    path('api/avaliacao/', include('avaliacao.urls')),
    path('api/token/', CustomTokenView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]