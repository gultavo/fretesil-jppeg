from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EmpresaViewSet, CaminhoneiroViewSet

router = DefaultRouter()
router.register(r'empresas', EmpresaViewSet)
router.register(r'motoristas', CaminhoneiroViewSet)

urlpatterns = [
    path('', include(router.urls)),
]