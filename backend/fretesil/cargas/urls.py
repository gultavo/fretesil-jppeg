from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CargaViewSet

router = DefaultRouter()
# Usamos basename porque o queryset é dinâmico (muda por usuário)
router.register(r'lista', CargaViewSet, basename='cargas')

urlpatterns = [
    path('', include(router.urls)),
]