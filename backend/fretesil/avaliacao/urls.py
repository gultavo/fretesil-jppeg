from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AvaliacaoViewSet, AvaliacaoCaminhoneiroViewSet # Adicione o novo ViewSet aqui

router = DefaultRouter()
router.register(r'blacklist', AvaliacaoViewSet)
router.register(r'avaliar-caminhoneiro', AvaliacaoCaminhoneiroViewSet)

urlpatterns = [
    path('', include(router.urls)),
]