from django.urls import path, include
from .views import EmpresaViewSet, CaminhoneiroViewSet
from rest_framework import routers

router = routers.DefaultRouter()
router.register(r'empresas', EmpresaViewSet)
router.register(r'caminhoneiros', CaminhoneiroViewSet)

urlpatterns = [
    path('', include(router.urls)),
]